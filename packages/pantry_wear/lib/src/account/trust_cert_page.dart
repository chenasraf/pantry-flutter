import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../pairing/cert_panel.dart';
import '../widgets/wear_centre.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';

/// Accepting the certificate of a server the watch is already signed in to.
///
/// The phone is where this decision is normally made and pushed across, and
/// for most wearers it always will be. This exists for the case where it
/// cannot be: a phone that validates the server through a certificate
/// authority installed on *it* accepts nothing and so has nothing to push, and
/// a watch holds no such authority and never will. Without a screen of its own
/// the watch would read whatever the phone mirrors to it and be unable to send
/// a single change back, for as long as it was set up.
class TrustCertPage extends StatefulWidget {
  const TrustCertPage({super.key});

  @override
  State<TrustCertPage> createState() => _TrustCertPageState();
}

class _TrustCertPageState extends State<TrustCertPage> {
  X509Certificate? _cert;
  String? _hostKey;
  var _unreadable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  /// Read back the certificate the handshake refused, so the wearer has
  /// something to decide about. The server is the session's — a watch reaches
  /// exactly one — rather than the host the refusal named, so a refusal that
  /// has since been cleared still opens on the right certificate.
  Future<void> _probe() async {
    final url = AuthService.instance.credentials?.serverUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      if (mounted) setState(() => _unreadable = true);
      return;
    }
    X509Certificate? cert;
    try {
      cert = await CertTrustService.instance.probe(uri);
    } catch (e) {
      debugPrint('[TrustCertPage] probe threw: $e');
    }
    if (!mounted) return;
    if (cert == null) {
      setState(() => _unreadable = true);
      return;
    }
    final isHttps = uri.scheme != 'http';
    setState(() {
      _cert = cert;
      _hostKey = CertTrustService.hostKey(
        uri.host,
        uri.hasPort ? uri.port : (isHttps ? 443 : 80),
        isHttps: isHttps,
      );
    });
  }

  /// Pin it, then push what has been waiting. Leaving on its own is the point:
  /// the wearer came here to get their changes sent, not to read that they
  /// might be.
  Future<void> _trust() async {
    final cert = _cert;
    final hostKey = _hostKey;
    if (cert == null || hostKey == null) return;
    await CertTrustService.instance.pin(hostKey, cert);
    unawaited(SyncManager.instance.flushNow());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cert = _cert;
    final hostKey = _hostKey;
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: switch ((cert, hostKey)) {
          (final X509Certificate c, final String host) => WearCertPanel(
            host: host,
            fingerprint: CertTrustService.fingerprintOf(c),
            onTrust: () => unawaited(_trust()),
          ),
          _ when _unreadable => WearCentre(
            padding: WearMetrics.bandInsets(context),
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
                  m.wear.certUnreadable,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(m.wear.certUnreadable),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _ => WearCentre(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        },
      ),
    );
  }
}
