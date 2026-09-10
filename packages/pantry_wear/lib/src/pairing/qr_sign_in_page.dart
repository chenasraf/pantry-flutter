import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/utils/server_url.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../wear_shape.dart';
import '../widgets/wear_centre.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import 'wear_pairing_client.dart';

/// Signing the watch in with nothing but the watch.
///
/// Nextcloud's Login Flow v2 is a device authorization grant: the device that
/// wants the credential never needs a browser, it needs *a* browser somewhere
/// while it polls. So the watch draws the login URL as a QR code, any phone's
/// camera opens it, and the poll picks the grant up. No companion app and no
/// Data Layer, which makes this the only sign-in a watch built without Google
/// Play services can perform.
///
/// The address is typed. That is the one text field on this watch that is not
/// a number, and the argument for it is that a server address is not a secret:
/// a mistake is a failed connection and a retry, which is exactly what typing
/// a password is not.
class QrSignInPage extends StatefulWidget {
  const QrSignInPage({super.key});

  @override
  State<QrSignInPage> createState() => _QrSignInPageState();
}

enum _Step {
  /// Which Nextcloud, typed on Wear's own IME.
  address,

  /// Asking the server for a login flow.
  starting,

  /// The code is up and the poll is running.
  showing,

  /// The server's certificate is one this watch cannot verify, and the wearer
  /// is being asked whether to pin it.
  untrusted,

  /// Nothing further will happen without the wearer starting over.
  failed,
}

class _QrSignInPageState extends State<QrSignInPage> {
  /// How often the grant is asked for. Nextcloud's own desktop client polls at
  /// about this rate, and the wearer is holding a phone up to their wrist for
  /// the whole of it.
  static const _pollInterval = Duration(seconds: 2);

  /// Nextcloud discards a login-flow token 20 minutes after minting it, and an
  /// expired token answers exactly as an unapproved one does. Without a
  /// ceiling of our own the poll would run forever behind a wakelock, which on
  /// a watch is a flat battery rather than a wasted request.
  static const _codeLifetime = Duration(minutes: 20);

  /// How long one round waits before the next takes over. Generous, since the
  /// traffic is proxied through a phone over Bluetooth and a slow round is
  /// still a round.
  static const _pollTimeout = Duration(seconds: 15);

  final _address = TextEditingController(text: 'https://');

  var _step = _Step.address;
  String? _failure;

  String _server = '';
  LoginFlowResult? _flow;
  Timer? _poll;
  bool _asking = false;
  DateTime? _showingSince;

  /// The certificate the wearer is being asked about, and the host it belongs
  /// to. Kept so trusting pins the exact certificate that was displayed rather
  /// than whatever a second probe would find.
  X509Certificate? _pendingCert;
  String? _pendingCertHostKey;

  @override
  void initState() {
    super.initState();
    // The moment the code is up is the moment the wearer has a phone in their
    // other hand and cannot flick their wrist, so a screen that dims is a dead
    // end rather than an annoyance. Scoped to this page — a wakelock left on
    // outlives the reason for it.
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _address.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<void> _start() async {
    final server = normalizeServerUrl(_address.text);
    setState(() {
      _server = server;
      _step = _Step.starting;
      _failure = null;
    });
    try {
      final flow = await AuthService.instance.initiateLoginFlow(server);
      if (!mounted) return;
      setState(() {
        _flow = flow;
        _showingSince = DateTime.now();
        _step = _Step.showing;
      });
      _poll = Timer.periodic(_pollInterval, (_) => unawaited(_ask()));
    } catch (e) {
      if (!mounted) return;
      if (CertTrustService.isHandshakeFailure(e)) {
        await _offerCertificate(server);
        return;
      }
      _fail(m.wear.qrUnreachable);
    }
  }

  /// Read back the certificate the handshake refused, so the wearer has
  /// something to decide about.
  ///
  /// A watch has no browser and no phone to be handed the pins by — that is
  /// the whole reason this path exists — so a self-signed server is reachable
  /// from here or from nowhere. What it can offer is the same trust-on-first-
  /// use decision the phone's login screen offers, in a yes/no shape.
  Future<void> _offerCertificate(String server) async {
    final uri = Uri.tryParse(server);
    X509Certificate? cert;
    if (uri != null) {
      try {
        cert = await CertTrustService.instance.probe(uri);
      } catch (e) {
        debugPrint('[QrSignInPage] probe threw: $e');
      }
    }
    if (!mounted) return;
    if (cert == null || uri == null) {
      _fail(m.wear.certUnreadable);
      return;
    }
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    setState(() {
      _pendingCert = cert;
      _pendingCertHostKey = CertTrustService.hostKey(
        uri.host,
        port,
        isHttps: uri.scheme == 'https',
      );
      _step = _Step.untrusted;
    });
  }

  Future<void> _trustCertificate() async {
    final cert = _pendingCert;
    final hostKey = _pendingCertHostKey;
    if (cert == null || hostKey == null) return;
    await CertTrustService.instance.pin(hostKey, cert);
    if (!mounted) return;
    _pendingCert = null;
    _pendingCertHostKey = null;
    await _start();
  }

  /// One round of the poll. A 404 is Login Flow v2's "nobody has approved this
  /// yet", and so is a token the server has since discarded — which is what
  /// the lifetime above is for.
  ///
  /// A round that is still in flight when the next tick arrives is skipped
  /// rather than run alongside: a watch's radio is proxied through a phone and
  /// rounds that overlap only compete for it. The timeout is what keeps one
  /// stalled connection from stopping the poll for good.
  Future<void> _ask() async {
    final flow = _flow;
    final since = _showingSince;
    if (flow == null || since == null || _asking) return;
    if (DateTime.now().difference(since) > _codeLifetime) {
      _fail(m.wear.qrExpired);
      return;
    }
    _asking = true;
    NextcloudCredentials? credentials;
    try {
      credentials = await AuthService.instance
          .pollLoginFlow(_server, flow)
          .timeout(_pollTimeout);
    } catch (e) {
      // A round that fails is not a flow that has: the phone approving it may
      // be a minute away, and the radio drops in and out on a wrist.
      debugPrint('[QrSignInPage] poll round failed: $e');
      return;
    } finally {
      _asking = false;
    }
    // `_poll` being gone means this round outlived the code it belongs to —
    // the wearer started over, or the lifetime ran out while it was in flight.
    if (credentials == null || !mounted || _poll == null) return;
    await _signedIn();
  }

  /// The grant landed and is already saved. Nothing here reports success: the
  /// shell replacing this route is the outcome, and a screen that announced it
  /// would be one more tap between the wearer and their lists.
  Future<void> _signedIn() async {
    _poll?.cancel();
    _poll = null;
    await WearPairingClient.instance.adoptLocalSignIn();
    if (mounted) Navigator.of(context).pop();
  }

  void _fail(String reason) {
    _poll?.cancel();
    _poll = null;
    setState(() {
      _failure = reason;
      _step = _Step.failed;
    });
  }

  void _startOver() {
    _poll?.cancel();
    _poll = null;
    setState(() {
      _flow = null;
      _showingSince = null;
      _failure = null;
      _step = _Step.address;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: wearGround,
    body: EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: switch (_step) {
        _Step.address => _AddressStep(
          controller: _address,
          onContinue: () => unawaited(_start()),
        ),
        _Step.starting => const _Spinner(),
        _Step.showing => QrCodeCard(loginUrl: _flow!.loginUrl),
        _Step.untrusted => _CertStep(
          host: _pendingCertHostKey!,
          fingerprint: CertTrustService.fingerprintOf(_pendingCert!),
          onTrust: () => unawaited(_trustCertificate()),
        ),
        _Step.failed => _FailedStep(
          reason: _failure ?? m.wear.qrUnreachable,
          onStartOver: _startOver,
        ),
      },
    ),
  );
}

/// Which Nextcloud, over Wear's own IME.
///
/// The field opens in URL mode and offers keyboard and handwriting; there is
/// no microphone on this platform's IME, so an address is typed rather than
/// spoken.
class _AddressStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onContinue;

  const _AddressStep({required this.controller, required this.onContinue});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(
              start: WearShape.isRound ? 26 : 14,
              end: WearShape.isRound ? 26 : 14,
              top: constraints.maxHeight * 0.2,
              bottom: constraints.maxHeight * 0.34,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.wear.qrServer,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(m.wear.qrServer),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  autofocus: true,
                  // A server address is always LTR, whatever the wearer's
                  // locale, so the field does not follow the layout.
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => onContinue(),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'cloud.example.com',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: WearCta.insetFor(constraints.maxHeight),
          child: WearCta(
            key: const ValueKey('show-qr-code'),
            icon: Icons.qr_code_2,
            label: m.wear.qrShowCode,
            onTap: onContinue,
          ),
        ),
      ],
    ),
  );
}

/// The code, and nothing else.
///
/// This is the one screen that discards the two-plane theme outright: its only
/// job is to be read by a camera, and light modules on the app's own ground
/// were refused because one decoder reading them is not every decoder — a code
/// nobody's camera can read looks exactly like a code nobody has pointed a
/// camera at yet.
///
/// Nothing names the host underneath it. There is no way to arrive here
/// without having typed that address on the previous screen, so the safety a
/// caption would buy is already paid for, and the width it costs is width the
/// code needs.
class QrCodeCard extends StatelessWidget {
  final String loginUrl;

  /// Modules of margin around the code, the QR spec's own minimum. A watch has
  /// less room to spend on a quiet zone than anything else that has ever drawn
  /// one.
  static const _quietModules = 4;

  const QrCodeCard({super.key, required this.loginUrl});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // A round screen can only show the square inscribed in it, and the corners
    // of a QR are exactly what a decoder needs — so the code is sized off that
    // square rather than off the width.
    final side = WearShape.isRound
        ? size.shortestSide / 1.414
        : size.shortestSide;
    return Center(
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: QrImageView(
          data: loginUrl,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
          // qr_flutter takes the quiet zone in pixels; a module is roughly the
          // side over 33 at the version a login URL lands on, which keeps the
          // margin quoted in the spec's own unit.
          padding: EdgeInsets.all(_quietModules * (side / 33)),
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

/// The certificate this watch cannot verify, laid out to be compared against
/// what the wearer expects.
///
/// The way to decline is the back gesture every pushed route carries: refusing
/// a certificate is leaving, not a second button.
class _CertStep extends StatelessWidget {
  final String host;
  final String fingerprint;
  final VoidCallback onTrust;

  const _CertStep({
    required this.host,
    required this.fingerprint,
    required this.onTrust,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(
              start: WearShape.isRound ? 24 : 12,
              end: WearShape.isRound ? 24 : 12,
              top: constraints.maxHeight * 0.16,
              bottom: constraints.maxHeight * 0.34,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gpp_maybe_outlined,
                  size: 20,
                  color: wearNoticeInk,
                ),
                const SizedBox(height: 6),
                Text(
                  m.login.untrustedCertTitle,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(
                    m.login.untrustedCertTitle,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.wear.certUntrustedBody(host),
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(
                    m.wear.certUntrustedBody(host),
                  ),
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  m.login.certFingerprint,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(m.login.certFingerprint),
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                // Monospace and full, wrapping rather than truncating: the
                // wearer is comparing it against something, and a fingerprint
                // with its middle elided compares equal to far too much.
                Text(
                  fingerprint,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.35,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: WearCta.insetFor(constraints.maxHeight),
          child: WearCta(
            key: const ValueKey('trust-cert'),
            icon: Icons.lock_outline,
            label: m.wear.certTrust,
            warning: true,
            onTap: onTrust,
          ),
        ),
      ],
    ),
  );
}

/// What went wrong, and the one thing that can be done about it — which is
/// always to go back to the address, since every failure this screen can
/// report is one a different or re-approved server would not produce.
class _FailedStep extends StatelessWidget {
  final String reason;
  final VoidCallback onStartOver;

  const _FailedStep({required this.reason, required this.onStartOver});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(
          child: WearCentre(
            padding: EdgeInsetsDirectional.only(
              start: WearShape.isRound ? 26 : 14,
              end: WearShape.isRound ? 26 : 14,
              bottom: constraints.maxHeight * 0.28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 20,
                  color: Colors.white38,
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(reason),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: WearCta.insetFor(constraints.maxHeight),
          child: WearCta(
            key: const ValueKey('qr-start-over'),
            icon: Icons.refresh,
            label: m.wear.qrStartOver,
            onTap: onStartOver,
          ),
        ),
      ],
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
