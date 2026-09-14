import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_scroll_indicator.dart';

/// The certificate this watch cannot verify, laid out to be compared against
/// what the wearer expects.
///
/// The way to decline is the back gesture every pushed route carries: refusing
/// a certificate is leaving, not a second button.
///
/// Shared by the two places the question can arise — a watch signing itself in
/// against a server it has never reached, and one whose server it could reach
/// yesterday — because it is the same question and the wearer answers it with
/// the same evidence.
class WearCertPanel extends StatelessWidget {
  /// `host[:port]`, named in the body so the wearer knows what they are
  /// deciding about.
  final String host;

  /// Colon-separated uppercase hex of the SHA-256 over the certificate.
  final String fingerprint;

  final VoidCallback onTrust;

  const WearCertPanel({
    super.key,
    required this.host,
    required this.fingerprint,
    required this.onTrust,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(
          child: WearScrollIndicator(
            child: SingleChildScrollView(
              padding: WearMetrics.bandInsets(context).copyWith(
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
