import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'i18n.dart';
import 'services/auth_service.dart';
import 'services/background_notification_task.dart';
import 'services/locale_service.dart';
import 'services/category_service.dart';
import 'services/checklist_service.dart';
import 'services/house_service.dart';
import 'services/local_notifications_service.dart';
import 'services/note_service.dart';
import 'services/photo_service.dart';
import 'services/prefs_service.dart';
import 'services/theming_service.dart';
import 'views/home/home_view.dart';
import 'views/login/login_view.dart';
import 'views/notifications_intro/notifications_intro_view.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    WakelockPlus.enable();
  }
  await AuthService.instance.loadCredentials();
  await PrefsService.instance.load();
  await LocalNotificationsService.instance.init();
  if (AuthService.instance.isLoggedIn) {
    await Future.wait([
      ThemingService.instance.fetchTheme(),
      HouseService.instance.cache.load(),
      CategoryService.instance.cache.load(),
      ChecklistService.instance.cache.load(),
      PhotoService.instance.cache.load(),
      NoteService.instance.cache.load(),
    ]);
    // Kick off the periodic background poll if notifications are enabled.
    if (PrefsService.instance.notificationsEnabled) {
      unawaited(registerBackgroundNotificationPoll());
    }
  }
  LocaleService.instance.apply();
  runApp(const PantryApp());
}

class PantryApp extends StatefulWidget {
  const PantryApp({super.key});

  @override
  State<PantryApp> createState() => PantryAppState();
}

class PantryAppState extends State<PantryApp> {
  bool _isLoggedIn = AuthService.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChange);
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onLoginSuccess() async {
    await ThemingService.instance.fetchTheme();
    _isLoggedIn = true;
    final nextRoute = PrefsService.instance.notificationsIntroSeen
        ? '/home'
        : '/notifications-intro';
    rootNavigatorKey.currentState?.pushReplacementNamed(nextRoute);
    if (mounted) setState(() {});
  }

  void _onIntroDone() {
    rootNavigatorKey.currentState?.pushReplacementNamed('/home');
  }

  Future<void> _onLogout() async {
    await cancelBackgroundNotificationPoll();
    await LocalNotificationsService.instance.cancelAll();
    await AuthService.instance.logout();
    ThemingService.instance.clear();
    await Future.wait([
      PrefsService.instance.clear(),
      HouseService.instance.cache.clear(),
      CategoryService.instance.cache.clear(),
      ChecklistService.instance.cache.clear(),
      PhotoService.instance.cache.clear(),
      NoteService.instance.cache.clear(),
    ]);
    _isLoggedIn = false;
    rootNavigatorKey.currentState?.pushReplacementNamed('/login');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = ThemingService.instance.effectiveColor;
    final locale = LocaleService.instance.effectiveLocale;
    return Directionality(
      textDirection: LocaleService.instance.textDirection,
      child: MaterialApp(
        key: ValueKey(locale),
        navigatorKey: rootNavigatorKey,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: m.common.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: color,
          ).copyWith(primary: color),
          useMaterial3: true,
          popupMenuTheme: PopupMenuThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            position: PopupMenuPosition.under,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: color,
            brightness: Brightness.dark,
          ).copyWith(primary: color),
          useMaterial3: true,
          popupMenuTheme: PopupMenuThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            position: PopupMenuPosition.under,
          ),
        ),
        themeMode: ThemeMode.system,
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            builder: (_) => _isLoggedIn
                ? (PrefsService.instance.notificationsIntroSeen
                      ? HomeView(onLogout: _onLogout)
                      : NotificationsIntroView(onDone: _onIntroDone))
                : LoginView(onLoginSuccess: _onLoginSuccess),
          ),
        ],
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(
                builder: (_) => HomeView(onLogout: _onLogout),
              );
            case '/notifications-intro':
              return MaterialPageRoute(
                builder: (_) => NotificationsIntroView(onDone: _onIntroDone),
              );
            case '/login':
            default:
              return MaterialPageRoute(
                builder: (_) => LoginView(onLoginSuccess: _onLoginSuccess),
              );
          }
        },
      ),
    );
  }
}
