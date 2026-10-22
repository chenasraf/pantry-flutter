import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';

/// Shown while the server answers writes with a redirect, which leaves every
/// read working and every change waiting — from inside the app the only sign
/// would be a sync dot that never clears.
///
/// Laid out like [SessionExpiredBanner], which it sits inside of: both draw
/// above the app and take the status-bar inset with them.
class ServerRedirectBanner extends StatelessWidget {
  final Widget child;

  /// Offered when the redirect does not reveal the server's new address, so
  /// the only fix is signing in against the one the user knows.
  final VoidCallback onSignIn;

  final bool suppressed;

  const ServerRedirectBanner({
    super.key,
    required this.child,
    required this.onSignIn,
    this.suppressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServerRedirect?>(
      valueListenable: AuthService.instance.serverRedirect,
      builder: (context, redirect, _) {
        if (redirect == null || suppressed) return child;
        return Column(
          children: [
            _Bar(redirect: redirect, onSignIn: onSignIn),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final ServerRedirect redirect;
  final VoidCallback onSignIn;

  const _Bar({required this.redirect, required this.onSignIn});

  Future<void> _adopt() async {
    if (await AuthService.instance.adoptRedirectedServerUrl()) {
      await ServerVersionService.instance.fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final address = redirect.serverUrl;
    return Material(
      color: cs.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.swap_horiz, size: 20, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.common.serverMovedTitle,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address == null
                          ? m.common.serverMovedUnknownBody
                          : m.common.serverMovedBody(address),
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: address == null ? onSignIn : _adopt,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onErrorContainer,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        address == null
                            ? m.common.signInAgain
                            : m.common.useNewAddress,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
