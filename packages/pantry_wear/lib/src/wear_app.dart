import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/theming_service.dart';

import 'debug/channel_harness_view.dart';

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

class _WearHome extends StatelessWidget {
  const _WearHome();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checklist,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                m.common.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                auth.isLoggedIn
                    ? m.wear.signedInAs(auth.displayName ?? '')
                    : m.wear.notSignedIn,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChannelHarnessView(),
                    ),
                  ),
                  child: const Text('Channels'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
