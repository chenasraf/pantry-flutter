import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'i18n.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/background_notification_task.dart';
import 'services/cert_trust_service.dart';
import 'services/locale_service.dart';
import 'services/category_service.dart';
import 'services/checklist_service.dart';
import 'services/house_service.dart';
import 'services/list_link_service.dart';
import 'services/local_notifications_service.dart';
import 'services/nn_localizations.dart';
import 'services/store_service.dart';
import 'services/note_service.dart';
import 'services/photo_service.dart';
import 'services/prefs_service.dart';
import 'services/server_version_service.dart';
import 'services/share_intent_service.dart';
import 'services/widget_link_service.dart';
import 'services/theming_service.dart';
import 'services/widget_service.dart';
import 'sync/sync_manager.dart';
import 'utils/platform_info.dart';
import 'views/home/home_view.dart';
import 'views/login/login_view.dart';
import 'views/notifications_intro/notifications_intro_view.dart';
import 'views/onboarding/onboarding_pages.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/widget/widget_config_view.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Suppress a burst of 403 snackbars (e.g. SyncManager flushing several queued
/// ops that all violate the same revoked permission) down to one.
DateTime? _lastForbiddenSnackbar;

void _showPermissionDeniedSnackbar() {
  final now = DateTime.now();
  if (_lastForbiddenSnackbar != null &&
      now.difference(_lastForbiddenSnackbar!) < const Duration(seconds: 3)) {
    return;
  }
  _lastForbiddenSnackbar = now;
  rootScaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m.common.permissionDenied)));
}

/// Resolved at startup from `package_info_plus`. Defaulted to the bundled
/// onboarding baseline so anything that reads it before main() finishes still
/// has a sane value to compare against.
String appVersion = kAppOnboardingFirstVersion;

/// Initial route the native [WidgetConfigActivity] launches its Flutter engine
/// with. The lean widget-config app is run instead of the full app for it.
const kWidgetConfigRoutePrefix = '/widget-config/';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The lists-widget config activity runs this same entrypoint in its own
  // engine; branch to a lean selector app instead of the full app.
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (initialRoute.startsWith(kWidgetConfigRoutePrefix)) {
    await _runWidgetConfigApp(initialRoute);
    return;
  }

  if (kDebugMode) {
    WakelockPlus.enable();
  }

  // intl ships no Nynorsk (nn) data, so register it before the first frame or
  // the nn localization delegates throw when building their DateFormats.
  registerNnLocaleData();

  // Independent platform-channel reads run concurrently to roughly halve
  // cold-start wall-clock on the pre-frame critical path.
  await Future.wait([
    AuthService.instance.loadCredentials(),
    PrefsService.instance.load(),
    CertTrustService.instance.load(),
    LocalNotificationsService.instance.init(),
    PackageInfo.fromPlatform().then((info) => appVersion = info.version),
  ]);
  // Install pinned-cert HttpOverrides before any HTTP call fires so user-trusted
  // self-signed certs are accepted from the first request (fetches start below).
  CertTrustService.instance.install();
  // Seed the auth profile from cache so display name / server language / first
  // day of week are available on first frame without waiting for the network.
  AuthService.instance.hydrateFromCache();
  ThemingService.instance.loadCached();

  if (AuthService.instance.isLoggedIn) {
    // Awaited: the home view needs these on first frame to avoid an empty flash.
    await Future.wait([
      HouseService.instance.cache.load(),
      CategoryService.instance.cache.load(),
      StoreService.instance.cache.load(),
      ChecklistService.instance.cache.load(),
      PhotoService.instance.cache.load(),
      NoteService.instance.cache.load(),
      ServerVersionService.instance.loadCached(),
      SyncManager.instance.init(),
    ]);
    // Network-bound refreshes kept off the critical path; the cached theme color
    // already drives the initial paint. ServerVersionService must land before
    // ThemingService — on NC ≥ 34 the theme color comes from the cached
    // capabilities `theming` block.
    //
    // Exception: with unseen onboarding pending, await the capabilities fetch
    // (short timeout so offline launches still proceed) so onboarding's
    // `hasFeature(...)` checks don't fire off stale cached capabilities.
    if (hasPendingOnboardingCandidates(
      PrefsService.instance.lastSeenOnboardingVersion,
    )) {
      await ServerVersionService.instance.fetch().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      unawaited(ThemingService.instance.fetchTheme());
    } else {
      unawaited(
        ServerVersionService.instance.fetch().then(
          (_) => ThemingService.instance.fetchTheme(),
        ),
      );
    }
    // Re-apply the locale once the user profile lands — if there's no saved
    // locale pref, the effective locale falls back to the Nextcloud user
    // language, which isn't known until [refreshUserState] completes.
    unawaited(
      AuthService.instance.refreshUserState().then(
        (_) => LocaleService.instance.apply(),
      ),
    );
    // Refresh each home-screen widget's list payload from caches — item
    // counts drift as the user checks things off, and a fresh install wipes
    // HomeWidgetPreferences. Also resyncs the launcher quick actions.
    unawaited(WidgetService.instance.refreshAll());
    if (PrefsService.instance.notificationsEnabled) {
      unawaited(registerBackgroundNotificationPoll());
    }
  }
  LocaleService.instance.apply();
  ApiClient.onForbidden = _showPermissionDeniedSnackbar;
  unawaited(ShareIntentService.instance.init());
  WidgetLinkService.instance.init();
  unawaited(ListLinkService.instance.init());
  runApp(const PantryApp());
}

/// Boot a minimal app that shows only the widget list selector. Runs in the
/// [WidgetConfigActivity] engine, so it loads just enough (auth + list caches +
/// theme/locale) to render and save a selection.
Future<void> _runWidgetConfigApp(String route) async {
  final appWidgetId = int.tryParse(
    route.substring(kWidgetConfigRoutePrefix.length),
  );
  registerNnLocaleData();
  await Future.wait([
    AuthService.instance.loadCredentials(),
    PrefsService.instance.load(),
    CertTrustService.instance.load(),
  ]);
  CertTrustService.instance.install();
  AuthService.instance.hydrateFromCache();
  ThemingService.instance.loadCached();
  await Future.wait([
    HouseService.instance.cache.load(),
    ChecklistService.instance.cache.load(),
  ]);
  LocaleService.instance.apply();
  runApp(WidgetConfigApp(appWidgetId: appWidgetId ?? -1));
}

/// Minimal MaterialApp wrapper around [WidgetConfigView], themed and localised
/// like the main app for a consistent look.
class WidgetConfigApp extends StatelessWidget {
  final int appWidgetId;

  const WidgetConfigApp({super.key, required this.appWidgetId});

  @override
  Widget build(BuildContext context) {
    final color = ThemingService.instance.effectiveColor;
    return Directionality(
      textDirection: LocaleService.instance.textDirection,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: LocaleService.instance.effectiveLocale,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
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
        themeMode: ThemingService.instance.themeMode,
        home: WidgetConfigView(appWidgetId: appWidgetId),
      ),
    );
  }
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
      // workers can't reliably resolve platform brightness, and item counts
      // drift as lists change.
      PrefsService.instance.pushWidgetTheme();
      unawaited(WidgetService.instance.refreshAll());
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Pick the next route for a logged-in user, sequencing onboarding →
  /// notifications intro → home. Onboarding wins because it can recur on upgrade.
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
      StoreService.instance.cache.clear(),
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
          // Key on an explicit-change counter, not the locale value: a
          // background locale re-resolution must update translations in place,
          // not rebuild the navigator and close whatever route is open.
          key: ValueKey(LocaleService.instance.revision),
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: localizationsDelegates,
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
