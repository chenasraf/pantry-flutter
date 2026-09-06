import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../pairing/wear_pairing_client.dart';
import '../wear_shape.dart';
import '../widgets/wear_mechanics.dart';

/// Leaving, and the one thing leaving has to say first.
///
/// Signing out here does **not** revoke: the app password is the phone's own,
/// and revoking it from the wrist would sign the phone out too. It does clear,
/// though — "signed out" has to mean the household data is off a watch that
/// may have just been handed to someone else.
///
/// Which makes an unsent write the one thing worth interrupting for. A 401
/// happens *to* the wearer and holds the queue; this is chosen, and the
/// difference between the two is consent.
///
/// The page is the confirmation. It needs no second tap and no lapse timer:
/// arriving here took a deliberate push, and the leading-edge strip every
/// pushed route carries is a cancel a wearer can actually aim at, which a card
/// on a crowded page was not.
class SignOutPage extends StatefulWidget {
  const SignOutPage({super.key});

  @override
  State<SignOutPage> createState() => _SignOutPageState();
}

class _SignOutPageState extends State<SignOutPage> {
  /// The wearer chose to let the queue drain first. Signing out follows on its
  /// own once the count reaches zero, since waiting for it was the whole
  /// instruction.
  var _waiting = false;

  @override
  void initState() {
    super.initState();
    SyncManager.instance.pendingCount.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    SyncManager.instance.pendingCount.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_waiting || SyncManager.instance.pendingCount.value > 0) return;
    _waiting = false;
    unawaited(_signOut());
  }

  void _sendFirst() {
    setState(() => _waiting = true);
    unawaited(SyncManager.instance.flushNow());
  }

  Future<void> _signOut() async {
    await WearPairingClient.instance.forget();
    // The home swaps to the setup flow underneath; this route is still on top
    // of it and has to get out of the way.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final queued = SyncManager.instance.pendingCount.value;
    final pending = queued > 0;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: WearShape.isRound ? 26 : 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 20, color: _ink),
                const SizedBox(height: 6),
                Text(
                  m.wear.signOutTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pending ? m.wear.signOutPending(queued) : m.wear.signOutBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: pending ? _ink : Colors.white54,
                  ),
                ),
                const SizedBox(height: 10),
                if (_waiting)
                  const _Button(label: null)
                else if (pending) ...[
                  _Button(label: m.wear.signOutWait, onTap: _sendFirst),
                  const SizedBox(height: 6),
                  // Never the target under the finger that opened this page,
                  // and never the first one: leaving is what the page is for,
                  // and a wearer told what it costs is allowed to.
                  _Quiet(
                    label: m.wear.signOutAnyway,
                    onTap: () => unawaited(_signOut()),
                  ),
                ] else
                  _Button(
                    label: m.common.logout,
                    warning: true,
                    onTap: () => unawaited(_signOut()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _ink = Color(0xFFE0A0A0);

class _Button extends StatelessWidget {
  /// Null while the queue is draining: the label becomes the progress, and
  /// there is nothing to aim at until it finishes.
  final String? label;
  final bool warning;
  final VoidCallback? onTap;

  const _Button({required this.label, this.warning = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: warning ? const Color(0xFF3A1D1D) : const Color(0xFF17171A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Text(
          label ?? m.wear.signOutSending,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: label == null
                ? Colors.white38
                : (warning ? _ink : Colors.white),
          ),
        ),
      ),
    ),
  );
}

class _Quiet extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Quiet({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.white54),
      ),
    ),
  );
}
