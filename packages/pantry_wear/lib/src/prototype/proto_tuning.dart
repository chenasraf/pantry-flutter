import 'package:flutter/foundation.dart';

/// PROTOTYPE — the knobs the photos and notes skeletons are drawn by.
///
/// Structure was settled by grilling and the design by wearing it; what these
/// hold is feel, every piece of it a wrist judgement. Each page takes its own
/// values with it as it graduates to its implementation.
class ProtoTuning extends ChangeNotifier {
  /// Hand-rolled snap, or free scrolling.
  bool snapEnabled = true;

  /// How long a tick sits reversible before it commits.
  int undoMs = 2000;

  /// How far the falloff reaches, in rows.
  double falloffRows = 2.2;

  /// A row of two photo tiles. Taller than a checklist card because a tile is
  /// the content rather than a label for it.
  double photoRowExtent = 88;

  /// Between the two tiles in a photo row.
  double tileGap = 6;

  /// Fraction of the width held back at each side of a list. Photos and notes
  /// are taller than a checklist row, so they sit further from the centre line
  /// where a round screen is narrower, and want more of it.
  double tallSideInset = 0.05;

  bool offline = false;

  void update(void Function() change) {
    change();
    notifyListeners();
  }
}
