import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'services/background_notification_task.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'services/localizations_delegates.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'services/image_cache_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'services/list_link_service.dart';
import 'services/local_notifications_service.dart';
import 'package:pantry_core/services/nn_localizations.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'services/share_intent_service.dart';
import 'services/widget_link_service.dart';
import 'services/checklist_widget_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'services/widget_interactivity.dart';
import 'services/widget_service.dart';
import 'services/widget_theme.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'views/home/home_view.dart';
import 'views/login/login_view.dart';
import 'views/notifications_intro/notifications_intro_view.dart';
import 'views/onboarding/onboarding_pages.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/widget/checklist_widget_config_view.dart';
import 'views/widget/widget_config_view.dart';
import 'widgets/session_expired_banner.dart';

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

/// Initial routes the native widget-config activities launch their Flutter
/// engines with. The matching lean config app runs instead of the full app.
const kWidgetConfigRoutePrefix = '/widget-config/';
const kChecklistWidgetConfigRoutePrefix = '/checklist-widget-config/';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The widget-config activities run this same entrypoint in their own engines;
  // branch to the matching lean selector app instead of the full app.
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (initialRoute.startsWith(kChecklistWidgetConfigRoutePrefix)) {
    await _runChecklistWidgetConfigApp(initialRoute);
    return;
  }
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
    // Refresh each home-screen widget's payload from caches — item counts and
    // rows drift as the user checks things off, and a fresh install wipes
    // HomeWidgetPreferences. Also resyncs the launcher quick actions.
    unawaited(WidgetService.instance.refreshAll());
    unawaited(ChecklistWidgetService.instance.refreshAll());
    if (PrefsService.instance.notificationsEnabled) {
      unawaited(registerBackgroundNotificationPoll());
    }
  }
  LocaleService.instance.apply();
  ApiClient.onForbidden = _showPermissionDeniedSnackbar;
  unawaited(ShareIntentService.instance.init());
  WidgetLinkService.instance.init();
  unawaited(ListLinkService.instance.init());
  registerWidgetInteractivity();
  runApp(const PantryApp());
}

/// Load just enough (auth + list caches + theme/locale) for a widget-config
/// engine to render and save, then run [home] in a minimal themed app.
Future<void> _runConfigApp(Widget home) async {
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
    CategoryService.instance.cache.load(),
    StoreService.instance.cache.load(),
    LabelService.instance.cache.load(),
  ]);
  LocaleService.instance.apply();
  runApp(_LeanConfigApp(home: home));
}

Future<void> _runWidgetConfigApp(String route) async {
  final id = int.tryParse(route.substring(kWidgetConfigRoutePrefix.length));
  await _runConfigApp(WidgetConfigView(appWidgetId: id ?? -1));
}

Future<void> _runChecklistWidgetConfigApp(String route) async {
  final id = int.tryParse(
    route.substring(kChecklistWidgetConfigRoutePrefix.length),
  );
  await _runConfigApp(ChecklistWidgetConfigView(appWidgetId: id ?? -1));
}

/// Minimal MaterialApp wrapper for the widget-config screens, themed and
/// localised like the main app for a consistent look.
class _LeanConfigApp extends StatelessWidget {
  final Widget home;

  const _LeanConfigApp({required this.home});

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
        // The engine's initial route is the deep config path (e.g.
        // /checklist-widget-config/131); resolve any route to [home] so it
        // isn't reported as an unresolved initial route.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute(builder: (_) => home),
        ],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => home),
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
    PrefsService.instance.addListener(_pushWidgetTheme);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      invalidateWidgetTheme();
      unawaited(pushWidgetTheme());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocaleService.instance.removeListener(_rebuild);
    ThemingService.instance.removeListener(_rebuild);
    PrefsService.instance.removeListener(_pushWidgetTheme);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    invalidateWidgetTheme();
    unawaited(pushWidgetTheme());
  }

  void _pushWidgetTheme() => unawaited(pushWidgetTheme());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync widget data from the foreground isolate — background
      // workers can't reliably resolve platform brightness, and item counts
      // drift as lists change.
      invalidateWidgetTheme();
      unawaited(pushWidgetTheme());
      unawaited(WidgetService.instance.refreshAll());
      unawaited(ChecklistWidgetService.instance.refreshAll());
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

  /// True while the re-authentication screen the banner offers is on the stack.
  bool _reauthOpen = false;

  /// Re-authentication keeps the user where they were: the sign-in screen is
  /// pushed over the app and popped on success, so the caches, the open route
  /// and the held sync queue all survive the round trip.
  Future<void> _onReauthRequested() async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    setState(() => _reauthOpen = true);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => LoginView(
          onLoginSuccess: () async {
            await ServerVersionService.instance.fetch();
            await ThemingService.instance.fetchTheme();
            navigator.pop();
          },
        ),
      ),
    );
    if (mounted) setState(() => _reauthOpen = false);
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
      ImageCacheService.instance.manager.emptyCache(),
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
            final wrapped = PlatformInfo.isDesktopHost
                ? _EscapePopWrapper(child: child)
                : child;
            return SessionExpiredBanner(
              suppressed: _reauthOpen,
              onSignIn: _onReauthRequested,
              child: wrapped,
            );
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
