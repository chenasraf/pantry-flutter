import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/theming_service.dart';

import 'pairing/wear_pairing_client.dart';
import 'pairing/wear_setup_page.dart';
import 'shell/wear_shell.dart';

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
      home: const _WearHome(),
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
    return held ? WearSetupPage(client: _pairing) : const WearShell();
  }
}
