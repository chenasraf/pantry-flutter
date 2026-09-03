import 'package:home_widget/home_widget.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/platform_info.dart';

String? _lastPushed;

/// Push the effective theme to the Android home-screen widget, so it repaints
/// with the app. [PrefsService] resolves the name but cannot deliver it — the
/// watch shares that service and has no widget host, so the `home_widget` call
/// lives on this side of the boundary and the app drives it.
///
/// Fires on every [PrefsService] notification, most of which have nothing to do
/// with appearance, so unchanged values are dropped before crossing the channel.
Future<void> pushWidgetTheme() async {
  if (!PlatformInfo.isAndroidPhone) return;
  final resolved = PrefsService.instance.resolvedThemeName;
  if (resolved == _lastPushed) return;
  _lastPushed = resolved;
  await HomeWidget.saveWidgetData<String>('widget_theme', resolved);
  await HomeWidget.updateWidget(
    qualifiedAndroidName: 'dev.casraf.pantry.PantryWidgetProvider',
  );
}

/// Re-push on the next notification even if the value is unchanged. The
/// platform brightness can read stale at startup and after a resume, so those
/// call sites must not be swallowed by the dedupe above.
void invalidateWidgetTheme() => _lastPushed = null;
