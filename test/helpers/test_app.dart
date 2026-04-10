import 'package:flutter/material.dart';

/// Wraps [child] in a [MaterialApp] + [Scaffold] so widgets under test have
/// access to Directionality, theme, localization, Overlay, Navigator, and
/// ScaffoldMessenger.
Widget wrapForTest(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(useMaterial3: true),
    home: Scaffold(body: child),
  );
}
