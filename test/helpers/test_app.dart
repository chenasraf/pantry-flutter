import 'package:flutter/material.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:provider/provider.dart';

/// Wraps [child] in a [MaterialApp] + [Scaffold] so widgets under test have
/// access to Directionality, theme, localization, Overlay, Navigator, the
/// overlay toasts are shown in, and the [PrefsService] the app provides.
Widget wrapForTest(Widget child, {ThemeData? theme}) {
  return ChangeNotifierProvider<PrefsService>.value(
    value: PrefsService.instance,
    child: MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      builder: (context, home) => AppToastHost(
        textDirection: TextDirection.ltr,
        child: home ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: child),
    ),
  );
}
