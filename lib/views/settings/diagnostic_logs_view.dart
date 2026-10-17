import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/diagnostic_log.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry/services/diagnostic_report.dart';
import 'package:pantry/services/wear_diagnostics_host.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/settings/settings_tiles.dart';

enum _Source { device, watch }

class DiagnosticLogsView extends StatefulWidget {
  /// Drawn beside the settings sidebar rather than as a screen of its own, so
  /// the actions an app bar would carry sit beside the filters instead.
  final bool embedded;

  const DiagnosticLogsView({super.key, this.embedded = false});

  @override
  State<DiagnosticLogsView> createState() => _DiagnosticLogsViewState();
}

class _DiagnosticLogsViewState extends State<DiagnosticLogsView> {
  var _source = _Source.device;
  var _problemsOnly = false;
  var _watchLinkAvailable = false;

  List<LogEntry>? _deviceEntries;

  /// The watch's log as it arrived, kept whole so a share carries it verbatim.
  String? _watchLog;
  var _watchLoading = false;
  var _watchFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDevice());
    unawaited(_resolveWatchLink());
  }

  Future<void> _resolveWatchLink() async {
    final available = await WearLinkService.instance.isAvailable();
    if (mounted && available) setState(() => _watchLinkAvailable = true);
  }

  Future<void> _loadDevice() async {
    final entries = await DiagnosticLog.instance.entries();
    if (mounted) setState(() => _deviceEntries = entries);
  }

  Future<void> _loadWatch() async {
    setState(() {
      _watchLoading = true;
      _watchFailed = false;
    });
    final log = await WearDiagnosticsHost.instance.fetch();
    if (!mounted) return;
    setState(() {
      _watchLoading = false;
      _watchFailed = log == null;
      _watchLog = log ?? _watchLog;
    });
  }

  void _select(_Source source) {
    setState(() => _source = source);
    if (source == _Source.watch && _watchLog == null && !_watchLoading) {
      unawaited(_loadWatch());
    }
  }

  Future<void> _copy() async {
    final report = await DiagnosticReport.build(watchLog: _watchLog);
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    showAppToast(
      message: m.settings.diagnostics.copied,
      kind: ToastKind.success,
    );
  }

  Future<void> _share(BuildContext anchor) async {
    // An iPad presents the share sheet as a popover, which needs an origin.
    final box = anchor.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final report = await DiagnosticReport.build(watchLog: _watchLog);
      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pantry-diagnostics-$stamp.txt');
      await file.writeAsString(report);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        message: m.settings.diagnostics.shareFailed,
        kind: ToastKind.error,
      );
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.settings.diagnostics.clearTitle),
        content: Text(m.settings.diagnostics.clearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DiagnosticLog.instance.clear();
    await _loadDevice();
  }

  List<LogEntry>? get _entries => switch (_source) {
    _Source.device => _deviceEntries,
    _Source.watch => _watchLog == null ? null : LogEntry.parse(_watchLog!),
  };

  @override
  Widget build(BuildContext context) {
    final diagnostics = m.settings.diagnostics;
    final actions = [
      IconButton(
        tooltip: m.common.copy,
        icon: const Icon(Icons.copy_outlined),
        onPressed: _copy,
      ),
      Builder(
        builder: (anchor) => IconButton(
          tooltip: diagnostics.share,
          icon: Icon(Icons.adaptive.share),
          onPressed: () => _share(anchor),
        ),
      ),
      if (_source == _Source.device)
        IconButton(
          tooltip: m.common.clear,
          icon: const Icon(Icons.delete_outline),
          onPressed: _clear,
        ),
    ];
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(diagnostics.title), actions: actions),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          SettingsSectionBody(diagnostics.body),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: _filters()),
                if (widget.embedded) ...actions,
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _filters() {
    final diagnostics = m.settings.diagnostics;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_watchLinkAvailable)
          SegmentedButton<_Source>(
            segments: [
              ButtonSegment(
                value: _Source.device,
                label: Text(diagnostics.thisDevice),
              ),
              ButtonSegment(
                value: _Source.watch,
                label: Text(diagnostics.watch),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (s) => _select(s.single),
          ),
        FilterChip(
          label: Text(diagnostics.problemsOnly),
          selected: _problemsOnly,
          onSelected: (v) => setState(() => _problemsOnly = v),
        ),
      ],
    );
  }

  Widget _body() {
    final diagnostics = m.settings.diagnostics;
    if (_source == _Source.watch) {
      if (_watchLoading) {
        return _Message(diagnostics.watchLoading, busy: true);
      }
      if (_watchFailed && _watchLog == null) {
        return _Message(
          diagnostics.watchUnavailable,
          action: TextButton(
            onPressed: _loadWatch,
            child: Text(m.common.retry),
          ),
        );
      }
    }
    final all = _entries;
    if (all == null) return const Center(child: CircularProgressIndicator());
    final shown = [
      for (final e in all.reversed)
        if (!_problemsOnly || e.level != LogLevel.info) e,
    ];
    if (shown.isEmpty) return _Message(diagnostics.empty);
    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(bottom: 24),
      itemCount: shown.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _EntryTile(shown[i]),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final bool busy;
  final Widget? action;

  const _Message(this.text, {this.busy = false, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LogEntry entry;

  const _EntryTile(this.entry);

  static final _time = DateFormat('MMM d, HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (entry.level) {
      LogLevel.info => scheme.onSurfaceVariant,
      LogLevel.warning => scheme.tertiary,
      LogLevel.error => scheme.error,
    };
    final meta = theme.textTheme.labelSmall?.copyWith(color: color);
    // Log text is code-like and English whatever the app's language, so it
    // reads left to right even in an RTL locale.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_time.format(entry.time.toLocal())}  ${entry.level.name}  '
              '${entry.tag}',
              style: meta,
            ),
            const SizedBox(height: 2),
            SelectableText(
              entry.message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
