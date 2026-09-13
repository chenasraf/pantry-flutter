import 'package:flutter/material.dart';
import 'package:pantry/utils/app_toast.dart';

/// Wraps [child] in a [MaterialApp] + [Scaffold] so widgets under test have
/// access to Directionality, theme, localization, Overlay, Navigator, and the
/// overlay toasts are shown in.
Widget wrapForTest(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(useMaterial3: true),
    builder: (context, home) => AppToastHost(
      textDirection: TextDirection.ltr,
      child: home ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: child),
  );
}
