/// The two screen shapes Wear OS ships.
enum WearScreenShape { round, square }

/// Screen shape, fixed once before `runApp`.
///
/// Round draws curved rows — full width at the vertical centre, falling off
/// with distance from it — where square draws uniform ones, so shape is read
/// during layout rather than awaited. It arrives as a Dart entrypoint argument
/// instead of over a channel: the first channel round trip lands 311 ms after
/// the first frame, on a 671 ms cold start, which is a visible reflow on every
/// launch.
class WearShape {
  WearShape._();

  /// Round when nothing says otherwise. A square layout on a round screen has
  /// its row ends cut off by the bezel; round geometry on a square screen only
  /// leaves margin unused, so round is the safe answer to an unknown.
  static WearScreenShape _shape = WearScreenShape.round;

  static WearScreenShape get shape => _shape;

  static bool get isRound => _shape == WearScreenShape.round;

  static bool get isSquare => _shape == WearScreenShape.square;

  /// Called once by the watch entrypoint with the arguments the activity
  /// passed. Anything unrecognised leaves the default in place.
  static void markFrom(List<String> args) {
    if (args.contains('square')) {
      _shape = WearScreenShape.square;
    } else if (args.contains('round')) {
      _shape = WearScreenShape.round;
    }
  }
}
