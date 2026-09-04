import 'package:flutter/material.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/theming_service.dart';

import 'prototype/shell_prototype.dart';

/// Root of the watch app.
class PantryWearApp extends StatelessWidget {
  const PantryWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = ThemingService.instance.effectiveColor;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: LocaleService.instance.effectiveLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: baseLocalizationsDelegates,
      // A watch is dark by default and has no theme switcher of its own; an
      // OLED-friendly dark surface is also what keeps ambient draw down.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: color,
          brightness: Brightness.dark,
        ).copyWith(primary: color, surface: Colors.black),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const ShellPrototype(),
    );
  }
}
