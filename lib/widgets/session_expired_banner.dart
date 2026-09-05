import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';

/// Wraps every route so the degraded state is visible from wherever the user
/// is, not only the home tabs — a revoked credential is just as confusing three
/// screens deep.
///
/// It draws above the app rather than over it, and takes the status-bar inset
/// with it so the scaffold underneath doesn't pad for an inset it no longer
/// touches.
class SessionExpiredBanner extends StatelessWidget {
  final Widget child;
  final VoidCallback onSignIn;

  /// Hides the banner while the sign-in screen it offers is already open,
  /// where it would sit above the very form that resolves it.
  final bool suppressed;

  const SessionExpiredBanner({
    super.key,
    required this.child,
    required this.onSignIn,
    this.suppressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isUnauthorized,
      builder: (context, unauthorized, _) {
        if (!unauthorized || suppressed) return child;
        return Column(
          children: [
            _Bar(onSignIn: onSignIn),
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
  final VoidCallback onSignIn;

  const _Bar({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 20, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.common.sessionExpiredTitle,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.common.sessionExpiredBody,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onSignIn,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onErrorContainer,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(m.common.signInAgain),
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
