import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../../services/wear_pairing_host.dart';
import 'tips/watch_tips.dart';

/// The phone's side of the credential handoff.
///
/// It exists to put a human between a watch's request and this phone's app
/// password. Play services proves the requester is our own app on a watch
/// already paired to this phone — which is not the same as proving whose wrist
/// it is on, and in a household app a second wearer is an ordinary situation
/// rather than an attack.
class WatchPairingView extends StatefulWidget {
  const WatchPairingView({super.key});

  @override
  State<WatchPairingView> createState() => _WatchPairingViewState();
}

class _WatchPairingViewState extends State<WatchPairingView> {
  final _host = WearPairingHost.instance;

  /// True from Allow until the transfer settles. The modal it raises is the
  /// precondition, not reassurance: both carriers need this process alive with
  /// the link's listeners attached, and backgrounding the app mid-transfer
  /// leaves the watch with nothing.
  var _transferring = false;

  @override
  void initState() {
    super.initState();
    _host.reconsider();
    _host.pending.addListener(_onChanged);
    _host.paired.addListener(_onChanged);
  }

  @override
  void dispose() {
    _host.pending.removeListener(_onChanged);
    _host.paired.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _allow(WearPairingRequest request) async {
    setState(() => _transferring = true);
    final granted = await _host.grant(request);
    if (!mounted) return;
    setState(() => _transferring = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(granted ? m.watch.pairedSnack : m.watch.pairFailedSnack),
      ),
    );
  }

  Future<void> _unpair() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.watch.unpairTitle),
        content: Text(m.watch.unpairBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(m.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(m.watch.unpair),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _host.unpair();
  }

  @override
  Widget build(BuildContext context) {
    final request = _host.pending.value;
    final paired = _host.paired.value;
    return Scaffold(
      appBar: AppBar(title: Text(m.watch.title)),
      // The modal is a barrier over the whole route rather than a dialog,
      // because there is nothing useful to do behind it and a dismissed dialog
      // would leave the transfer running with no sign of it.
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            children: [
              if (request != null)
                _RequestCard(
                  request: request,
                  account: AuthService.instance.credentials?.loginName ?? '',
                  server: AuthService.instance.credentials?.serverUrl ?? '',
                  onAllow: () => _allow(request),
                  onDeny: _host.deny,
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    paired == null ? m.watch.waitingBody : m.watch.pairedBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (paired != null) ...[
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.watch_outlined),
                  title: Text(
                    paired.nodeName.isEmpty
                        ? m.watch.unnamedWatch
                        : paired.nodeName,
                    textDirection: detectTextDirection(paired.nodeName),
                  ),
                  subtitle: Text(m.watch.pairedStatus),
                ),
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: Text(m.watch.unpair),
                  subtitle: Text(m.watch.unpairSubtitle),
                  onTap: _unpair,
                ),
              ],
              // Under the pairing state rather than above it: a reader who
              // opened this page mid-handoff came for the request, and the
              // tips are what is here the rest of the time.
              const Divider(height: 24),
              const WatchTipsSection(),
            ],
          ),
          if (_transferring)
            const ModalBarrier(dismissible: false, color: Colors.black54),
          if (_transferring)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(m.watch.transferring),
                      const SizedBox(height: 4),
                      Text(
                        m.watch.transferringBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The confirmation. It names the watch and the account together, because
/// which account is being shared is the thing only this screen can say.
class _RequestCard extends StatelessWidget {
  final WearPairingRequest request;
  final String account;
  final String server;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _RequestCard({
    required this.request,
    required this.account,
    required this.server,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final name = request.nodeName.isEmpty
        ? m.watch.unnamedWatch
        : request.nodeName;
    return Card(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.watch.requestTitle(name),
              textDirection: detectTextDirection(name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(m.watch.requestBody(account, server)),
            const SizedBox(height: 8),
            Text(
              m.watch.requestWarning,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDeny, child: Text(m.watch.deny)),
                const SizedBox(width: 8),
                FilledButton(onPressed: onAllow, child: Text(m.watch.allow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
