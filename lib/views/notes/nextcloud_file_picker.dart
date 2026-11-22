import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/nextcloud_files_service.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/utils/item_modal_route.dart';

enum NextcloudPickMode {
  /// Pick a folder a new file can be created in.
  folder,

  /// Pick a text file small enough to become a note.
  noteFile,
}

/// Browse the account's Nextcloud files and pick a folder or a file, returned
/// as its path from the files root (`/` for the root itself), or null when
/// dismissed.
Future<String?> pickNextcloudPath(
  BuildContext context, {
  required NextcloudPickMode mode,
}) => Navigator.of(
  context,
).push<String>(itemModalRoute(NextcloudFilePicker(mode: mode)));

class NextcloudFilePicker extends StatefulWidget {
  final NextcloudPickMode mode;

  const NextcloudFilePicker({super.key, required this.mode});

  @override
  State<NextcloudFilePicker> createState() => _NextcloudFilePickerState();
}

class _NextcloudFilePickerState extends State<NextcloudFilePicker> {
  String _path = '/';
  RemoteFolderListing? _listing;
  bool _loading = true;
  String? _error;

  /// Bumped per navigation, so a slow folder answering after the user has
  /// moved on is dropped instead of replacing the folder they are in.
  int _request = 0;

  bool get _folderMode => widget.mode == NextcloudPickMode.folder;

  @override
  void initState() {
    super.initState();
    _open('/');
  }

  Future<void> _open(String path) async {
    final request = ++_request;
    setState(() {
      _path = path;
      _loading = true;
      _error = null;
    });
    try {
      final listing = await NextcloudFilesService.instance.listFolder(path);
      if (!mounted || request != _request) return;
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[NextcloudFilePicker] Failed to list $path: $e');
      if (!mounted || request != _request) return;
      setState(() {
        _listing = null;
        _loading = false;
        _error = e is ApiException
            ? e.serverMessage ?? m.notesWall.filePicker.failedToLoad
            : m.notesWall.filePicker.failedToLoad;
      });
    }
  }

  String get _parent {
    final i = _path.lastIndexOf('/');
    return i <= 0 ? '/' : _path.substring(0, i);
  }

  /// In folder mode files stay listed, greyed out, so a folder with files in
  /// it does not read as empty. In file mode only what the server would
  /// import is listed: a folder of photos is noise there.
  List<RemoteFileEntry> get _shown => [
    for (final entry in _listing?.children ?? const <RemoteFileEntry>[])
      if (entry.isFolder || _folderMode || entry.isImportableAsNote) entry,
  ];

  @override
  Widget build(BuildContext context) {
    final atRoot = _path == '/';
    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _open(_parent);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _folderMode
                ? m.notesWall.filePicker.chooseFolder
                : m.notesWall.filePicker.chooseFile,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Breadcrumb(path: _path, onOpen: _open),
            const Divider(height: 1),
            Expanded(child: _body(context)),
            if (_folderMode) _chooseBar(context),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _open(_path),
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }
    final entries = _shown;
    if (entries.isEmpty) {
      final hasHidden = _listing?.children.isNotEmpty ?? false;
      return Center(
        child: Text(
          !_folderMode && hasHidden
              ? m.notesWall.filePicker.noTextFiles
              : m.notesWall.filePicker.emptyFolder,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return ListTile(
          enabled: entry.isFolder || !_folderMode,
          leading: Icon(
            entry.isFolder ? Icons.folder : Icons.description_outlined,
          ),
          title: Text(
            entry.name,
            textDirection: detectTextDirection(entry.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: entry.isFolder ? const Icon(Icons.chevron_right) : null,
          onTap: () => entry.isFolder
              ? _open(entry.path)
              : Navigator.of(context).pop(entry.path),
        );
      },
    );
  }

  Widget _chooseBar(BuildContext context) {
    final folder = _listing?.folder;
    final writable = !_loading && (folder?.canCreateInside ?? false);
    final readOnly = !_loading && folder != null && !writable;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (readOnly)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: Text(
                  m.notesWall.filePicker.folderReadOnly,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            FilledButton(
              onPressed: writable
                  ? () => Navigator.of(context).pop(_path)
                  : null,
              child: Text(m.notesWall.filePicker.chooseThisFolder),
            ),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final String path;
  final ValueChanged<String> onOpen;

  const _Breadcrumb({required this.path, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final crumbs = <({String label, String path})>[
      (label: m.notesWall.filePicker.root, path: '/'),
      for (var i = 0; i < segments.length; i++)
        (label: segments[i], path: '/${segments.take(i + 1).join('/')}'),
    ];
    const separator = Icon(Icons.chevron_right, size: 18);
    // Reversed so a deep path keeps its current folder in view; the Align
    // keeps a short one at the start instead of the reversed end.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < crumbs.length; i++) ...[
              if (i > 0) separator,
              TextButton(
                onPressed: i == crumbs.length - 1
                    ? null
                    : () => onOpen(crumbs[i].path),
                child: Text(
                  crumbs[i].label,
                  textDirection: detectTextDirection(crumbs[i].label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
