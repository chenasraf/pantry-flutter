/// Quantities are free-form text — "3", "400 g", "2 x 1 L" — so stepping one
/// rewrites the first run of digits and leaves everything around it untouched.
final _numberRun = RegExp(r'\d+');

const int _maxQuantity = 9999;

/// The distance between neighbouring values on the quantity grid at [value]:
/// a 1-5-10 progression per decade, so the step grows with the number it
/// applies to. Without it, walking "400 g" up to "500 g" takes a hundred taps.
int _stepAt(int value) {
  if (value < 10) return 1;
  var decade = 10;
  while (decade * 10 <= value) {
    decade *= 10;
  }
  return value < 5 * decade ? decade ~/ 2 : decade;
}

/// The first grid value above [value]; off-grid numbers land on the grid rather
/// than carrying their offset along (123 → 150 → 200).
int _gridUp(int value) {
  final step = _stepAt(value);
  return (value ~/ step) * step + step;
}

/// The first grid value below [value]. The step comes from `value - 1` so a
/// value sitting on a band boundary descends into the band beneath it
/// (10 → 9, not 10 → 5).
int _gridDown(int value) {
  if (value <= 0) return 0;
  final step = _stepAt(value - 1);
  return ((value - 1) ~/ step) * step;
}

/// Step the number inside [quantity] one grid value up ([direction] positive)
/// or down, keeping the unit and any surrounding text. A quantity with no
/// number at all gains a leading "1" when stepped up.
String stepQuantity(String quantity, int direction) {
  final match = _numberRun.firstMatch(quantity);
  if (match == null) {
    if (direction <= 0) return quantity;
    return quantity.isEmpty ? '1' : '1 $quantity';
  }
  final current = int.tryParse(match.group(0)!);
  if (current == null) return quantity;
  final stepped = direction > 0 ? _gridUp(current) : _gridDown(current);
  final next = stepped > _maxQuantity ? _maxQuantity : stepped;
  return quantity.replaceRange(match.start, match.end, '$next');
}
