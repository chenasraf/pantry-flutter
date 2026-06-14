import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/platform_info.dart';

/// Width of the desktop item modal — sized to the phone form factor so the
/// layouts (originally designed for mobile) don't stretch awkwardly across a
/// 1600px monitor.
const double _kItemModalMaxWidth = 480;

/// Height cap for the desktop item modal — prevents the dialog from sprawling
/// vertically on tall displays. The Scaffold inside scrolls if its content
/// would overflow.
const double _kItemModalMaxHeight = 720;

/// Route used for "item view" and "item edit" navigation. On mobile it's a
/// standard full-screen `MaterialPageRoute`. On desktop it presents the page
/// as a centered, constrained dialog so the phone-shaped layout doesn't have
/// to fill the entire window. Use with `Navigator.push` /
/// `Navigator.pushReplacement` exactly like a MaterialPageRoute.
Route<T> itemModalRoute<T>(Widget child) {
  if (!isDesktop) {
    return MaterialPageRoute<T>(builder: (_) => child);
  }
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    barrierDismissible: true,
    barrierLabel: m.common.cancel,
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (_, _, _) => _ItemModalFrame(child: child),
    transitionsBuilder: (_, anim, _, c) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.985,
          end: 1,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: c,
      ),
    ),
  );
}

/// Centers the child page inside a width/height cap so the desktop dialog
/// looks like a phone screen floating over the dimmed app. SafeArea keeps the
/// modal clear of any desktop window decorations.
class _ItemModalFrame extends StatelessWidget {
  final Widget child;

  const _ItemModalFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _kItemModalMaxWidth,
            maxHeight: _kItemModalMaxHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
