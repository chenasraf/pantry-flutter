import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/pantry_wear.dart';

void main() {
  tearDown(() => WearShape.markFrom(const ['round']));

  test('reads the shape the activity passed', () {
    WearShape.markFrom(const ['square']);
    expect(WearShape.shape, WearScreenShape.square);
    expect(WearShape.isSquare, isTrue);
    expect(WearShape.isRound, isFalse);

    WearShape.markFrom(const ['round']);
    expect(WearShape.shape, WearScreenShape.round);
    expect(WearShape.isRound, isTrue);
  });

  test('keeps round when the argument is missing or unrecognised', () {
    WearShape.markFrom(const []);
    expect(WearShape.isRound, isTrue);

    WearShape.markFrom(const ['oblong']);
    expect(WearShape.isRound, isTrue);
  });

  test('an unrecognised argument does not undo a known one', () {
    WearShape.markFrom(const ['square']);
    WearShape.markFrom(const ['oblong']);
    expect(WearShape.isSquare, isTrue);
  });
}
