import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/wear_host_service.dart';
import '../wear_shape.dart';
import '../widgets/wear_mechanics.dart';
import 'qr_sign_in_page.dart';
import 'wear_pairing_client.dart';

/// What the watch shows before it has a session.
///
/// Every state here is driven by a signal that is real: whether the link
/// exists, whether anything is connected to it, and what the phone said back.
/// Notably absent is any hint about how long this should take —
/// `startRemoteActivity` resolves when the intent reached the phone, not when
/// anything handled it, so "the app isn't installed" and "they haven't looked
/// yet" are the same thing from here, and a timeout would fire mostly at
/// people who are merely slow.
class WearSetupPage extends StatefulWidget {
  final WearPairingClient client;

  const WearSetupPage({super.key, required this.client});

  @override
  State<WearSetupPage> createState() => _WearSetupPageState();
}

class _WearSetupPageState extends State<WearSetupPage> {
  /// Said once after the button is pressed, since the phone is where the rest
  /// of this happens and the watch has nothing further to report.
  String? _notice;

  Future<void> _openOnPhone() async {
    final opened = await WearHostService.instance.openOnPhone(
      'pantry://watch-setup',
    );
    if (!mounted) return;
    setState(
      () => _notice = opened ? m.wear.openedOnPhone : m.wear.openOnPhoneFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Round screens lose the corners, so the copy sits in a narrower column
    // than the square ones can afford.
    final inset = WearShape.isRound ? 26.0 : 14.0;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
          child: switch (widget.client.state) {
            WearSetupState.checking => const _Spinner(),
            WearSetupState.unavailable => _Message(
              icon: Icons.link_off,
              title: m.wear.setupNoLink,
              body: m.wear.setupNoLinkBody,
              qrSignIn: true,
            ),
            WearSetupState.noPhone => _Message(
              icon: Icons.phonelink_off,
              title: m.wear.setupNoPhone,
              body: m.wear.setupNoPhoneBody,
              qrSignIn: true,
            ),
            WearSetupState.phoneSignedOut => _Message(
              icon: Icons.person_off_outlined,
              title: m.wear.setupPhoneSignedOut,
              body: m.wear.setupPhoneSignedOutBody,
            ),
            WearSetupState.syncing => _Message(
              icon: Icons.sync,
              title: m.wear.setupSyncing,
              body: m.wear.setupSyncingBody,
              spinning: true,
            ),
            WearSetupState.waiting || WearSetupState.ready => _Waiting(
              notice: _notice,
              onOpenOnPhone: _openOnPhone,
            ),
          },
        ),
      ),
    );
  }
}

/// The state the wearer acts from: what is about to happen, and the one
/// button that starts it on the device that can finish it.
class _Waiting extends StatelessWidget {
  final String? notice;
  final VoidCallback onOpenOnPhone;

  const _Waiting({required this.notice, required this.onOpenOnPhone});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.watch_outlined, size: 22, color: scheme.primary),
        const SizedBox(height: 8),
        Text(
          m.wear.setupTitle,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(m.wear.setupTitle),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          m.wear.setupBody,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(m.wear.setupBody),
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onOpenOnPhone,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              child: Text(
                m.wear.openOnPhone,
                textDirection: detectTextDirection(m.wear.openOnPhone),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 7),
          Text(
            notice!,
            textAlign: TextAlign.center,
            textDirection: detectTextDirection(notice!),
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
        const _QrSignIn(),
      ],
    );
  }
}

/// The second way in, under the one that needs a phone.
///
/// Below rather than beside it because the handoff stays the advertised path.
/// It also rides the two dead ends: a watch with no Data Layer, or with no
/// phone connected to it, is precisely the watch this path exists for — those
/// screens can only say what has gone wrong, and this is the one thing the
/// wearer can still do about it.
class _QrSignIn extends StatelessWidget {
  const _QrSignIn();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 8),
    child: GestureDetector(
      onTap: () =>
          Navigator.of(context).push(wearRoute<void>(const QrSignInPage())),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Text(
          m.wear.qrSignIn,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(m.wear.qrSignIn),
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white24,
          ),
        ),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool spinning;

  /// A dead end the QR path can get the wearer out of, as opposed to one that
  /// is merely waiting on something.
  final bool qrSignIn;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.spinning = false,
    this.qrSignIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spinning)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          )
        else
          Icon(icon, size: 22, color: Colors.white38),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(title),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(body),
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        if (qrSignIn) const _QrSignIn(),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
