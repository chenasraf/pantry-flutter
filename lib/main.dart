import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'i18n.dart';
import 'services/auth_service.dart';
import 'services/background_notification_task.dart';
import 'services/cert_trust_service.dart';
import 'services/locale_service.dart';
import 'services/category_service.dart';
import 'services/checklist_service.dart';
import 'services/house_service.dart';
import 'services/local_notifications_service.dart';
import 'services/note_service.dart';
import 'services/photo_service.dart';
import 'services/prefs_service.dart';
import 'services/server_version_service.dart';
import 'services/share_intent_service.dart';
import 'services/widget_link_service.dart';
import 'services/theming_service.dart';
import 'sync/sync_manager.dart';
import 'utils/platform_info.dart';
import 'views/home/home_view.dart';
import 'views/login/login_view.dart';
import 'views/notifications_intro/notifications_intro_view.dart';
import 'views/onboarding/onboarding_pages.dart';
import 'views/onboarding/onboarding_view.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Resolved at startup from `package_info_plus`. Defaulted to the bundled
/// onboarding baseline so anything that reads it before main() finishes still
/// has a sane value to compare against.
String appVersion = kAppOnboardingFirstVersion;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    WakelockPlus.enable();
  }

  // Parallelize independent platform-channel work. AuthService.loadCredentials
  // and PrefsService.load are independent reads from secure storage;
  // PackageInfo and LocalNotificationsService.init touch other channels.
  // Doing them concurrently roughly halves cold-start wall-clock on the
  // pre-frame critical path.
  await Future.wait([
    AuthService.instance.loadCredentials(),
    PrefsService.instance.load(),
    CertTrustService.instance.load(),
    LocalNotificationsService.instance.init(),
    PackageInfo.fromPlatform().then((info) => appVersion = info.version),
  ]);
  // Install pinned-cert HttpOverrides before any HTTP call fires so
  // user-trusted self-signed certs are accepted from the very first
  // request (capabilities/theme/profile fetches start right below).
  CertTrustService.instance.install();
  // Both services are loaded; seed the auth profile from PrefsService's
  // cache so display name, server language, and first day of week are
  // available on first frame without waiting for the network refresh.
  AuthService.instance.hydrateFromCache();
  ThemingService.instance.loadCached();

  if (AuthService.instance.isLoggedIn) {
    // Disk caches are still awaited — the home view needs them on first
    // frame to avoid an empty flash.
    await Future.wait([
      HouseService.instance.cache.load(),
      CategoryService.instance.cache.load(),
      ChecklistService.instance.cache.load(),
      PhotoService.instance.cache.load(),
      NoteService.instance.cache.load(),
      ServerVersionService.instance.loadCached(),
      SyncManager.instance.init(),
    ]);
    // Network-bound refreshes — kept off the critical path. The cached
    // theme color already drives the initial paint; capabilities/version
    // and the profile fetch update listeners when they land.
    // ServerVersionService must land before ThemingService — on NC ≥ 34
    // the theme color comes from the cached capabilities `theming` block.
    unawaited(
      ServerVersionService.instance.fetch().then(
        (_) => ThemingService.instance.fetchTheme(),
      ),
    );
    // Re-apply the locale once the user profile lands — if there's no saved
    // locale pref, the effective locale falls back to the Nextcloud user
    // language, which isn't known until [refreshUserState] completes.
    unawaited(
      AuthService.instance.refreshUserState().then(
        (_) => LocaleService.instance.apply(),
      ),
    );
    // Rebuild the home-screen widget's pinned-list payload from caches —
    // a fresh install wipes HomeWidgetPreferences but secure-storage pins
    // may survive, so the widget would otherwise stay empty until the
    // next pin toggle.
    unawaited(PrefsService.instance.pushWidgetPinnedLists());
    // Kick off the periodic background poll if notifications are enabled.
    if (PrefsService.instance.notificationsEnabled) {
      unawaited(registerBackgroundNotificationPoll());
    }
  }
  LocaleService.instance.apply();
  unawaited(ShareIntentService.instance.init());
  WidgetLinkService.instance.init();
  runApp(const PantryApp());
}

class PantryApp extends StatefulWidget {
  const PantryApp({super.key});

  @override
  State<PantryApp> createState() => PantryAppState();
}

class _EscapePopWrapper extends StatelessWidget {
  final Widget child;
  const _EscapePopWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _PopRouteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{_PopRouteIntent: _PopRouteAction()},
        child: child,
      ),
    );
  }
}

class _PopRouteIntent extends Intent {
  const _PopRouteIntent();
}

class _PopRouteAction extends Action<_PopRouteIntent> {
  @override
  Object? invoke(covariant _PopRouteIntent intent) {
    final nav = rootNavigatorKey.currentState;
    if (nav?.canPop() == true) {
      nav!.maybePop();
    }
    return null;
  }
}

class PantryAppState extends State<PantryApp> with WidgetsBindingObserver {
  bool _isLoggedIn = AuthService.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleService.instance.addListener(_rebuild);
    ThemingService.instance.addListener(_rebuild);
    // Re-push the widget theme after first frame — at startup the platform
    // brightness can briefly report a stale value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrefsService.instance.pushWidgetTheme();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocaleService.instance.removeListener(_rebuild);
    ThemingService.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    PrefsService.instance.pushWidgetTheme();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync widget data from the foreground isolate — background
      // workers can't reliably resolve platform brightness, and the
      // pinned-list payload can drift if HomeWidgetPreferences is wiped.
      PrefsService.instance.pushWidgetTheme();
      PrefsService.instance.pushWidgetPinnedLists();
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Pick the next route for a logged-in user. Onboarding takes priority over
  /// the notifications intro — both run only once, but onboarding is more
  /// likely to recur (a returning user upgrading the app), so we sequence
  /// onboarding → notifications intro → home.
  String _nextPostLoginRoute() {
    final hasUnseenOnboarding = resolveOnboardingPages(
      PrefsService.instance.lastSeenOnboardingVersion,
    ).isNotEmpty;
    if (hasUnseenOnboarding) return '/onboarding';
    if (!PrefsService.instance.notificationsIntroSeen) {
      return '/notifications-intro';
    }
    return '/home';
  }

  Future<void> _onLoginSuccess() async {
    await ServerVersionService.instance.fetch();
    await ThemingService.instance.fetchTheme();
    _isLoggedIn = true;
    rootNavigatorKey.currentState?.pushReplacementNamed(_nextPostLoginRoute());
    if (mounted) setState(() {});
  }

  void _onOnboardingDone() {
    if (!PrefsService.instance.notificationsIntroSeen) {
      rootNavigatorKey.currentState?.pushReplacementNamed(
        '/notifications-intro',
      );
    } else {
      rootNavigatorKey.currentState?.pushReplacementNamed('/home');
    }
  }

  void _onIntroDone() {
    rootNavigatorKey.currentState?.pushReplacementNamed('/home');
  }

  /// Cold-start widget for a logged-in user. Mirrors [_nextPostLoginRoute] but
  /// returns a widget instead of a route name so it can plug directly into
  /// `onGenerateInitialRoutes`.
  Widget _resolveLoggedInInitial() {
    final route = _nextPostLoginRoute();
    switch (route) {
      case '/onboarding':
        return OnboardingView(
          appVersion: appVersion,
          onDone: _onOnboardingDone,
        );
      case '/notifications-intro':
        return NotificationsIntroView(onDone: _onIntroDone);
      default:
        return HomeView(onLogout: _onLogout);
    }
  }

  Future<void> _onLogout() async {
    await cancelBackgroundNotificationPoll();
    await LocalNotificationsService.instance.cancelAll();
    await AuthService.instance.logout();
    ThemingService.instance.clear();
    ServerVersionService.instance.clear();
    await Future.wait([
      PrefsService.instance.clear(),
      HouseService.instance.cache.clear(),
      CategoryService.instance.cache.clear(),
      ChecklistService.instance.cache.clear(),
      PhotoService.instance.cache.clear(),
      NoteService.instance.cache.clear(),
      SyncManager.instance.reset(),
    ]);
    _isLoggedIn = false;
    rootNavigatorKey.currentState?.pushReplacementNamed('/login');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = ThemingService.instance.effectiveColor;
    final locale = LocaleService.instance.effectiveLocale;
    final appBarTheme = PlatformInfo.isMacOS
        ? const AppBarTheme(toolbarHeight: 66)
        : null;
    return ChangeNotifierProvider<PrefsService>.value(
      value: PrefsService.instance,
      child: Directionality(
        textDirection: LocaleService.instance.textDirection,
        child: MaterialApp(
          key: ValueKey(locale),
          debugShowCheckedModeBanner: false,
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
            appBarTheme: appBarTheme,
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
            appBarTheme: appBarTheme,
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              position: PopupMenuPosition.under,
            ),
          ),
          themeMode: ThemingService.instance.themeMode,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            if (!PlatformInfo.isDesktopHost) return child;
            return _EscapePopWrapper(child: child);
          },
          onGenerateInitialRoutes: (initialRoute) => [
            MaterialPageRoute(
              builder: (_) => _isLoggedIn
                  ? _resolveLoggedInInitial()
                  : LoginView(onLoginSuccess: _onLoginSuccess),
            ),
          ],
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/home':
                return MaterialPageRoute(
                  builder: (_) => HomeView(onLogout: _onLogout),
                );
              case '/onboarding':
                return MaterialPageRoute(
                  builder: (_) => OnboardingView(
                    appVersion: appVersion,
                    onDone: _onOnboardingDone,
                  ),
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
      ),
    );
  }
}
