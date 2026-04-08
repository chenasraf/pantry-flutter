import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'i18n.dart';
import 'services/auth_service.dart';
import 'services/checklist_service.dart';
import 'services/prefs_service.dart';
import 'services/theming_service.dart';
import 'views/home/home_view.dart';
import 'views/login/login_view.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    WakelockPlus.enable();
  }
  await AuthService.instance.loadCredentials();
  await PrefsService.instance.load();
  if (AuthService.instance.isLoggedIn) {
    await Future.wait([
      ThemingService.instance.fetchTheme(),
      ChecklistService.instance.loadFromDisk(),
    ]);
  }
  runApp(const PantryApp());
}

class PantryApp extends StatefulWidget {
  const PantryApp({super.key});

  @override
  State<PantryApp> createState() => PantryAppState();
}

class PantryAppState extends State<PantryApp> {
  bool _isLoggedIn = AuthService.instance.isLoggedIn;

  Future<void> _onLoginSuccess() async {
    await ThemingService.instance.fetchTheme();
    _isLoggedIn = true;
    rootNavigatorKey.currentState?.pushReplacementNamed('/home');
    if (mounted) setState(() {});
  }

  Future<void> _onLogout() async {
    await AuthService.instance.logout();
    ThemingService.instance.clear();
    await PrefsService.instance.clear();
    _isLoggedIn = false;
    rootNavigatorKey.currentState?.pushReplacementNamed('/login');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = ThemingService.instance.effectiveColor;
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: m.common.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: color,
        ).copyWith(primary: color),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: color,
          brightness: Brightness.dark,
        ).copyWith(primary: color),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute(
          builder: (_) => _isLoggedIn
              ? HomeView(onLogout: _onLogout)
              : LoginView(onLoginSuccess: _onLoginSuccess),
        ),
      ],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeView(onLogout: _onLogout),
            );
          case '/login':
          default:
            return MaterialPageRoute(
              builder: (_) => LoginView(onLoginSuccess: _onLoginSuccess),
            );
        }
      },
    );
  }
}
