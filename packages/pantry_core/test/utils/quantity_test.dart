import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/quantity.dart';

String up(String q) => stepQuantity(q, 1);
String down(String q) => stepQuantity(q, -1);

/// What one tap on the quantity stepper means.
///
/// The step scales with the value, so "400 g" reaches "500 g" in two taps
/// instead of a hundred — while small counts still move one at a time.
void main() {
  test('counts one at a time below ten', () {
    expect(up('0'), '1');
    expect(up('3'), '4');
    expect(up('9'), '10');
    expect(down('4'), '3');
    expect(down('1'), '0');
  });

  test('never goes below zero', () {
    expect(down('0'), '0');
  });

  test('widens the step as the value grows', () {
    final values = <String>['0'];
    for (var i = 0; i < 26; i++) {
      values.add(up(values.last));
    }
    expect(values, [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
      '10', '15', '20', '25', '30', '35', '40', '45', //
      '50', '60', '70', '80', '90', //
      '100', '150', '200', '250',
    ]);
  });

  test('walks back down the same grid it walked up', () {
    final values = <String>['250'];
    for (var i = 0; i < 26; i++) {
      values.add(down(values.last));
    }
    expect(values.reversed, [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
      '10', '15', '20', '25', '30', '35', '40', '45', //
      '50', '60', '70', '80', '90', //
      '100', '150', '200', '250',
    ]);
  });

  test('pulls a value between grid points onto the grid', () {
    expect(up('123'), '150');
    expect(down('123'), '100');
    expect(up('7777'), '8000');
    expect(down('7777'), '7000');
  });

  test('keeps the unit and the space around it', () {
    expect(up('400 g'), '450 g');
    expect(down('400 g'), '350 g');
    expect(up('100mL'), '150mL');
    expect(up('2 x 500 g'), '3 x 500 g');
  });

  test('starts counting a quantity that is only a unit', () {
    expect(up('kg'), '1 kg');
    expect(up(''), '1');
    expect(down('kg'), 'kg');
    expect(down(''), '');
  });

  test('stops at the largest quantity it can hold', () {
    expect(up('9000'), '9999');
    expect(up('9999'), '9999');
    expect(down('9999'), '9000');
  });

  test('leaves a number too large to read alone', () {
    const huge = '99999999999999999999999 g';
    expect(up(huge), huge);
    expect(down(huge), huge);
  });
}
