import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/platform_info.dart';

import '../utils/window_bounds.dart';

/// Carries the desktop window's frame across launches: the app reopens the
/// size, position and maximized state it was last left in.
class WindowService with WindowListener, WidgetsBindingObserver {
  WindowService._();
  static final WindowService instance = WindowService._();

  /// Resize and move arrive as a stream of events while the pointer is down,
  /// and only the frame the user settles on is worth a write.
  static const _saveDebounce = Duration(milliseconds: 300);

  Timer? _saveTimer;

  /// Restore the remembered frame and hand the window to the user.
  ///
  /// Runs before the first frame so the window is never seen at a size the
  /// user did not pick.
  Future<void> restore() async {
    if (!PlatformInfo.isDesktop) return;
    await windowManager.ensureInitialized();
    try {
      await _applySavedFrame();
    } finally {
      // The macOS runner holds the window back at launch — unlike the Windows
      // and Linux runners, which wait for Flutter's first frame, it would
      // otherwise show the storyboard's default frame before this ran. Nothing
      // else brings it on screen, so this has to happen however the above went.
      if (PlatformInfo.isMacOS) await windowManager.show();
    }
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _applySavedFrame() async {
    final prefs = PrefsService.instance;
    final saved = prefs.windowBounds;
    if (saved != null) {
      await windowManager.setBounds(await _fitToDisplays(saved));
    }
    if (prefs.windowMaximized) await windowManager.maximize();
  }

  Future<Rect> _fitToDisplays(Rect saved) async {
    final primary = await screenRetriever.getPrimaryDisplay();
    final displays = await screenRetriever.getAllDisplays();
    return resolveWindowBounds(
      saved: saved,
      primary: _visibleFrame(primary),
      displays: [for (final display in displays) _visibleFrame(display)],
    );
  }

  Rect _visibleFrame(Display display) {
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  @override
  void onWindowLeaveFullScreen() => _scheduleSave();

  /// Switching away is the last moment the frame is certainly still writable —
  /// quitting from another app gives no warning the debounce would survive.
  @override
  void onWindowBlur() => _flush();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _flush();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(_save()));
  }

  void _flush() {
    if (_saveTimer?.isActive != true) return;
    _saveTimer!.cancel();
    unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = PrefsService.instance;
    // A minimized or full-screen window reports a frame that belongs to the
    // state, not to the window — writing it would lose the one to come back to.
    if (await windowManager.isMinimized()) return;
    if (await windowManager.isFullScreen()) return;

    final maximized = await windowManager.isMaximized();
    await prefs.setWindowMaximized(maximized);
    if (maximized) return;

    await prefs.setWindowBounds(await windowManager.getBounds());
  }
}
