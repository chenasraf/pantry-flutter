import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../pairing/wear_pairing_client.dart';
import '../prototype/degraded_proto.dart';
import '../prototype/proto_tuning.dart';

/// Who the watch is signed in as, and the way back out.
///
/// Signing out here does **not** revoke: the app password is the phone's, and
/// revoking it from the wrist would sign the phone out too.
///
/// It does clear, though — "signed out" has to mean the household data is off
/// the watch, which may well have just been handed to someone else. So an
/// unsent check-off is the one thing a sign-out has to say out loud first: a
/// 401 happens *to* the wearer and holds the queue, where this is chosen, and
/// the difference between the two is consent.
class AccountPage extends StatefulWidget {
  /// PROTOTYPE — carries the degraded-state cycle control, which is the only
  /// way to wear the treatments without a real revocation.
  final ProtoTuning? tuning;

  const AccountPage({super.key, this.tuning});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  /// A watch has no room for a dialog and no cancel a wearer can aim at, so
  /// the confirmation is a second tap on the same target — and it lapses on
  /// its own, which a dialog left open on a wrist would not.
  var _confirming = false;
  Timer? _lapse;

  /// The wearer chose to let the queue drain first. Sign-out follows on its
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
    _lapse?.cancel();
    super.dispose();
  }

  void _onQueueChanged() {
    if (!_waiting || SyncManager.instance.pendingCount.value > 0) return;
    _waiting = false;
    _signOut();
  }

  void _tap() {
    if (!_confirming) {
      setState(() => _confirming = true);
      _lapse = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _confirming = false);
      });
      return;
    }
    if (_waiting) return;
    if (SyncManager.instance.pendingCount.value > 0) {
      _lapse?.cancel();
      setState(() => _waiting = true);
      unawaited(SyncManager.instance.flushNow());
      return;
    }
    _signOut();
  }

  void _signOut() {
    _lapse?.cancel();
    unawaited(WearPairingClient.instance.forget());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AuthService.instance.credentials?.loginName ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              name.isEmpty ? m.wear.account : m.wear.signedInAs(name),
              textAlign: TextAlign.center,
              textDirection: detectTextDirection(name),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: SyncManager.instance.pendingCount,
              builder: (context, queued, _) => _SignOut(
                confirming: _confirming,
                waiting: _waiting,
                queued: queued,
                onTap: _tap,
                onSignOutAnyway: _signOut,
              ),
            ),
            if (kDebugMode && widget.tuning != null) ...[
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: widget.tuning!,
                builder: (context, _) => ProtoDegradedSwitch(
                  value: widget.tuning!.degraded,
                  onChanged: (v) =>
                      widget.tuning!.update(() => widget.tuning!.degraded = v),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The sign-out control, in whichever of its three states applies: the plain
/// label, the second-tap confirmation, and — when the queue still holds
/// something — what is unsent, with the offer to send it first.
class _SignOut extends StatelessWidget {
  final bool confirming;
  final bool waiting;
  final int queued;
  final VoidCallback onTap;
  final VoidCallback onSignOutAnyway;

  const _SignOut({
    required this.confirming,
    required this.waiting,
    required this.queued,
    required this.onTap,
    required this.onSignOutAnyway,
  });

  @override
  Widget build(BuildContext context) {
    final pending = queued > 0;
    final label = switch ((confirming, waiting, pending)) {
      (_, true, _) => m.wear.signOutSending,
      (true, _, true) => m.wear.signOutWait,
      (true, _, false) => m.wear.signOutConfirm,
      _ => m.common.logout,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (confirming && pending) ...[
          Text(
            m.wear.signOutPending(queued),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE0A0A0)),
          ),
          const SizedBox(height: 6),
        ],
        _SignOutButton(
          label: label,
          highlighted: confirming,
          onTap: waiting ? null : onTap,
        ),
        // Only ever the second target, and never the one under the finger that
        // opened the confirmation: leaving is what this page is for, and a
        // wearer who has been told what it costs is allowed to.
        if (confirming && pending && !waiting) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onSignOutAnyway,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: Text(
                m.wear.signOutAnyway,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;

  const _SignOutButton({
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFF3A1D1D)
              : const Color(0xFF17171A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: highlighted ? const Color(0xFFE0A0A0) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
