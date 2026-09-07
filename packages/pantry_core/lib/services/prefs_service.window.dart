part of 'prefs_service.dart';

/// Smallest window frame worth restoring. A saved value below this came from a
/// corrupt write or a platform reporting a collapsed frame, and restoring it
/// would hand the user a window too small to find the resize handles on.
const kMinWindowSize = Size(320, 320);

/// Parse a `x,y,width,height` frame in logical pixels, rejecting anything that
/// would not survive being handed back to the window manager.
Rect? decodeWindowBounds(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(',');
  if (parts.length != 4) return null;
  final values = [for (final part in parts) double.tryParse(part)];
  if (values.any((v) => v == null || !v.isFinite)) return null;
  final rect = Rect.fromLTWH(values[0]!, values[1]!, values[2]!, values[3]!);
  if (rect.width < kMinWindowSize.width ||
      rect.height < kMinWindowSize.height) {
    return null;
  }
  return rect;
}

/// Whole logical pixels: a window frame carries no meaning below one, and the
/// fractions a scaled display reports back would otherwise drift the saved
/// value on every launch.
String encodeWindowBounds(Rect bounds) => [
  bounds.left.round(),
  bounds.top.round(),
  bounds.width.round(),
  bounds.height.round(),
].join(',');

extension PrefsServiceWindowSetters on PrefsService {
  Future<void> setWindowBounds(Rect bounds) async {
    if (_windowBounds == bounds) return;
    _windowBounds = bounds;
    await _storage.write(
      key: PrefsService._windowBoundsKey,
      value: encodeWindowBounds(bounds),
    );
    notifyListeners();
  }

  Future<void> setWindowMaximized(bool value) async {
    if (_windowMaximized == value) return;
    _windowMaximized = value;
    await _storage.write(
      key: PrefsService._windowMaximizedKey,
      value: value.toString(),
    );
    notifyListeners();
  }
}
