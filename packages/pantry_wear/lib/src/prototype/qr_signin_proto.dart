import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../wear_shape.dart';
import '../widgets/wear_mechanics.dart';

/// PROTOTYPE — signing the watch in with nothing but the watch.
///
/// Nextcloud's Login Flow v2 is a device authorization grant: the device that
/// wants the credential never needs a browser, it needs *a* browser somewhere
/// while it polls. So the watch draws the login URL as a QR code, any phone's
/// camera opens it, and the poll already in `AuthService` picks up the grant.
/// No companion app, no Data Layer, and therefore the only sign-in a watch
/// built without Google Play services can perform.
///
/// Three things here cannot be settled on paper, and this exists to wear them:
///
/// 1. **Does a `TextField` raise Wear's own IME over a Flutter surface, and
///    does that IME offer dictation?** The whole server-address step rests on
///    it — and so does the billed-total field the trip's summary wants, which
///    makes the same bet and has not been worn either.
/// 2. **Which QR treatment actually scans off a watch**, at what quiet zone,
///    and does the screen stay lit long enough to be scanned at all.
/// 3. **Does the round trip complete** from a watch with no phone link.
///
/// It deliberately **does not persist the credential**: the poll is its own
/// rather than `AuthService.pollLoginFlow`, which saves on success and would
/// sign a live session out from under the wearer. What lands here is shown and
/// dropped.
class QrSignInProto extends StatefulWidget {
  const QrSignInProto({super.key});

  @override
  State<QrSignInProto> createState() => _QrSignInProtoState();
}

/// How the code is drawn. The differences are the ones a scanner cares about,
/// not the ones a designer does.
enum QrTreatment {
  /// A white card, dark modules, as large as the round screen's inscribed
  /// square allows. Discards the two-plane theme outright on the argument that
  /// this screen's only job is to be read by a camera.
  paper('Paper'),

  /// Light modules on the app's own ground. Looks like the rest of the watch;
  /// many decoders refuse an inverted code, which is the point of trying it
  /// rather than asserting it.
  inverted('Inverted'),

  /// The paper card, smaller, with the host it belongs to named underneath —
  /// so a wearer can tell *which* server they are about to hand an account to.
  captioned('Captioned');

  const QrTreatment(this.label);
  final String label;
}

enum _Step { address, starting, showing, granted, failed }

class _QrSignInProtoState extends State<QrSignInProto> {
  final _url = TextEditingController(text: 'https://');

  _Step _step = _Step.address;
  QrTreatment _treatment = QrTreatment.paper;

  /// Modules of margin around the code. Four is the spec's minimum; a watch
  /// has less room to spend on it than anything else that has ever drawn one.
  int _quietModules = 4;

  String? _loginUrl;
  String? _pollEndpoint;
  String? _pollToken;
  String _server = '';

  Timer? _poll;
  int _attempts = 0;
  String _lastStatus = '—';
  String? _error;
  String? _grantedTo;

  @override
  void dispose() {
    _poll?.cancel();
    _url.dispose();
    super.dispose();
  }

  String _normalize(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  Future<void> _start() async {
    final server = _normalize(_url.text);
    setState(() {
      _server = server;
      _step = _Step.starting;
      _error = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$server/index.php/login/v2'),
            headers: const {'User-Agent': 'Pantry Wear (prototype)'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw Exception('login/v2 answered ${res.statusCode}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final poll = data['poll'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _loginUrl = data['login'] as String;
        _pollEndpoint = poll['endpoint'] as String;
        _pollToken = poll['token'] as String;
        _step = _Step.showing;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _step = _Step.failed;
      });
    }
  }

  void _startPolling() {
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final res = await http.post(
          Uri.parse(_pollEndpoint!),
          body: {'token': _pollToken},
        );
        if (!mounted) return;
        setState(() {
          _attempts++;
          _lastStatus = '${res.statusCode}';
        });
        // 404 is Login Flow v2's "nobody has approved this yet".
        if (res.statusCode == 404) return;
        timer.cancel();
        if (res.statusCode != 200) {
          setState(() {
            _error = 'poll answered ${res.statusCode}';
            _step = _Step.failed;
          });
          return;
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          // The app password is deliberately neither shown nor kept.
          _grantedTo = data['loginName'] as String?;
          _step = _Step.granted;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _attempts++;
          _lastStatus = 'error';
        });
      }
    });
  }

  void _restart() {
    _poll?.cancel();
    setState(() {
      _step = _Step.address;
      _attempts = 0;
      _lastStatus = '—';
      _error = null;
      _grantedTo = null;
      _loginUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) => EdgeDismissible(
    onDismiss: () => Navigator.of(context).pop(),
    child: Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: SafeArea(
        child: switch (_step) {
          _Step.address => _AddressStep(controller: _url, onContinue: _start),
          _Step.starting => const _Centred(child: CircularProgressIndicator()),
          _Step.showing => _ShowingStep(
            loginUrl: _loginUrl!,
            server: _server,
            treatment: _treatment,
            quietModules: _quietModules,
            attempts: _attempts,
            lastStatus: _lastStatus,
            onTreatment: (t) => setState(() => _treatment = t),
            onQuiet: (q) => setState(() => _quietModules = q),
          ),
          _Step.granted => _Outcome(
            icon: Icons.check_circle_outline,
            title: 'Granted',
            body: '${_grantedTo ?? '?'}\ncredential discarded',
            onAgain: _restart,
          ),
          _Step.failed => _Outcome(
            icon: Icons.error_outline,
            title: 'Failed',
            body: _error ?? '',
            onAgain: _restart,
          ),
        },
      ),
    ),
  );
}

/// The step the whole option rests on: Wear's own IME, raised by an ordinary
/// `TextField`. The wearer picks keyboard, handwriting or voice from the
/// system's chooser — which is why no `RecognizerIntent` method is needed on
/// the host channel, and why the outcome of *this screen* decides that.
class _AddressStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onContinue;

  const _AddressStep({required this.controller, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inset = WearShape.isRound ? 26.0 : 14.0;
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your server',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              // A server address is always LTR, whatever the wearer's locale.
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => onContinue(),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'cloud.example.com',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onContinue,
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
                  child: Text(
                    'Show code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The code, the treatment switcher, and the poll's own state laid bare —
/// because "did it work" and "is it still trying" are the two things a wearer
/// holding a phone up to their wrist cannot otherwise tell apart.
class _ShowingStep extends StatelessWidget {
  final String loginUrl;
  final String server;
  final QrTreatment treatment;
  final int quietModules;
  final int attempts;
  final String lastStatus;
  final ValueChanged<QrTreatment> onTreatment;
  final ValueChanged<int> onQuiet;

  const _ShowingStep({
    required this.loginUrl,
    required this.server,
    required this.treatment,
    required this.quietModules,
    required this.attempts,
    required this.lastStatus,
    required this.onTreatment,
    required this.onQuiet,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // A round screen can only show the square inscribed in it, and the corners
    // of a QR are exactly what a decoder needs — so the code is sized off that
    // square, not off the width.
    final square = WearShape.isRound
        ? size.shortestSide / 1.414
        : size.shortestSide;
    final side = treatment == QrTreatment.captioned ? square * 0.74 : square;

    final light = treatment == QrTreatment.inverted
        ? const Color(0xFF0B0B0C)
        : Colors.white;
    final dark = treatment == QrTreatment.inverted
        ? Colors.white
        : Colors.black;

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  color: light,
                  borderRadius: BorderRadius.circular(
                    treatment == QrTreatment.inverted ? 0 : 8,
                  ),
                ),
                child: QrImageView(
                  data: loginUrl,
                  version: QrVersions.auto,
                  backgroundColor: light,
                  // qr_flutter takes the quiet zone as pixels; a module is
                  // roughly the side over 33 for the version a login URL
                  // lands on, so this keeps the knob in the spec's own unit.
                  padding: EdgeInsets.all(quietModules * (side / 33)),
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: dark,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: dark,
                  ),
                ),
              ),
              if (treatment == QrTreatment.captioned) ...[
                const SizedBox(height: 5),
                Text(
                  Uri.parse(server).host,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const Text(
                  'Point your phone camera here',
                  style: TextStyle(fontSize: 9, color: Colors.white38),
                ),
              ],
            ],
          ),
        ),
        _ProtoBar(
          treatment: treatment,
          quietModules: quietModules,
          attempts: attempts,
          lastStatus: lastStatus,
          onTreatment: onTreatment,
          onQuiet: onQuiet,
        ),
      ],
    );
  }
}

/// PROTOTYPE — the variant switcher and the poll's state. Sits over the code
/// deliberately: whatever it hides is width the real screen would have to give
/// the code back.
class _ProtoBar extends StatelessWidget {
  final QrTreatment treatment;
  final int quietModules;
  final int attempts;
  final String lastStatus;
  final ValueChanged<QrTreatment> onTreatment;
  final ValueChanged<int> onQuiet;

  const _ProtoBar({
    required this.treatment,
    required this.quietModules,
    required this.attempts,
    required this.lastStatus,
    required this.onTreatment,
    required this.onQuiet,
  });

  @override
  Widget build(BuildContext context) {
    final next =
        QrTreatment.values[(treatment.index + 1) % QrTreatment.values.length];
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'poll $attempts · $lastStatus',
            style: const TextStyle(fontSize: 9, color: Colors.white54),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: treatment.label, onTap: () => onTreatment(next)),
              const SizedBox(width: 6),
              _Chip(
                label: 'quiet $quietModules',
                onTap: () => onQuiet(quietModules >= 6 ? 1 : quietModules + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: Colors.white),
      ),
    ),
  );
}

class _Outcome extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onAgain;

  const _Outcome({
    required this.icon,
    required this.title,
    required this.body,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) => _Centred(
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          _Chip(label: 'again', onTap: onAgain),
        ],
      ),
    ),
  );
}

class _Centred extends StatelessWidget {
  final Widget child;

  const _Centred({required this.child});

  @override
  Widget build(BuildContext context) => Center(child: child);
}
