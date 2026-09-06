import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/theming_service.dart';

import 'pairing/wear_pairing_client.dart';
import 'pairing/wear_setup_page.dart';
import 'shell/wear_shell.dart';

/// Root of the watch app.
///
/// It listens to the two services that decide how the watch looks, because
/// both of their values can land from the paired phone while the app is open —
/// a language changed on the phone, an accent refetched there — and a root that
/// only read them at startup would draw the previous answer until something
/// else happened to rebuild it.
///
/// Listening is all it does: [MaterialApp] is never keyed on
/// [LocaleService.revision], so a landed value and a wrist choice alike are a
/// rebuild rather than a teardown. Keying would drop every pushed route, and on
/// a watch each level back is a deliberate edge-strip drag rather than a button.
class PantryWearApp extends StatefulWidget {
  const PantryWearApp({super.key});

  @override
  State<PantryWearApp> createState() => _PantryWearAppState();
}

class _PantryWearAppState extends State<PantryWearApp> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onAppearance);
    ThemingService.instance.addListener(_onAppearance);
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onAppearance);
    ThemingService.instance.removeListener(_onAppearance);
    super.dispose();
  }

  void _onAppearance() {
    if (mounted) setState(() {});
  }

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
      // Deliberately not `const`. A rebuild reaches a child only when the
      // child widget differs from the one already there, and a `const` widget
      // is canonicalised to a single instance — so a landed language would
      // repaint the frame and nothing inside it.
      home: _WearHome(),
    );
  }
}

/// Signed in or not, and the one place that answers it.
///
/// The setup flow lives behind this rather than as a route the shell pushes,
/// because a watch that is signed out has nothing to push it *from* — and an
/// unpair arriving mid-shop has to take the shell away, not layer a screen
/// over it.
class _WearHome extends StatefulWidget {
  const _WearHome();

  @override
  State<_WearHome> createState() => _WearHomeState();
}

class _WearHomeState extends State<_WearHome> {
  final _pairing = WearPairingClient.instance;

  @override
  void initState() {
    super.initState();
    _pairing.addListener(_onPairing);
    // Started either way: unpair is a phone-side control, so a signed-in watch
    // has to be listening for it too.
    unawaited(_pairing.start());
  }

  @override
  void dispose() {
    _pairing.removeListener(_onPairing);
    super.dispose();
  }

  void _onPairing() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // A credential arrives before the house data behind it, so being signed in
    // is not yet enough to draw the shell — an empty list is a worse first
    // impression than a stated wait.
    final held =
        !AuthService.instance.isLoggedIn ||
        _pairing.state == WearSetupState.syncing;
    // Not `const`, for the same reason `home` is not: the shell is what a
    // landed language has to reach.
    return held ? WearSetupPage(client: _pairing) : WearShell();
  }
}
