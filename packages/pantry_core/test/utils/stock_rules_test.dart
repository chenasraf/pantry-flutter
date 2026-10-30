import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/quantity.dart';

/// The vectors are a copy of the server's tests/stock-vectors.json, which also
/// pins lib/Service/StockRules.php and the web's src/utils/stock.ts. Refresh
/// the copy whenever the server's file changes.
final Map<String, dynamic> vectors =
    jsonDecode(File('test/fixtures/stock-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> group_(String key) =>
    (vectors[key] as List).cast<Map<String, dynamic>>();

StockFields fields(Map<String, dynamic> item) => StockFields(
  stockMode: StockMode.tryParse(item['stockMode']),
  stockLevel: StockLevel.tryParse(item['stockLevel']),
  quantity: item['quantity'] as String?,
  target: item['target'] as String?,
  reorderPoint: item['reorderPoint'] as String?,
  expiresAt: item['expiresAt'] as int?,
  shelfLifeDays: item['shelfLifeDays'] as int?,
);

void main() {
  group('firstNumber', () {
    for (final v in group_('firstNumber')) {
      test(jsonEncode(v['text']), () {
        expect(
          firstNumber(v['text'] as String?),
          (v['value'] as num?)?.toDouble(),
        );
      });
    }
  });

  group('evaluate', () {
    for (final v in group_('evaluate')) {
      test(v['name'], () {
        final result = evaluateStock(fields(v['item'] as Map<String, dynamic>));
        expect(result.status.wire, v['stockStatus']);
        expect(result.shortfall, v['shortfall']);
      });
    }
  });

  group('startingOnHand', () {
    for (final v in group_('startingOnHand')) {
      test(v['name'], () {
        expect(
          startingOnHand(v['quantity'] as String?, v['target'] as String?),
          v['result'],
        );
      });
    }
  });

  group('convert', () {
    for (final v in group_('convert')) {
      test(v['name'], () {
        final result = convertStock(
          fields(v['item'] as Map<String, dynamic>),
          StockMode.parse(v['toMode']),
        );
        final expected = v['result'] as Map<String, dynamic>;
        expect(result.stockMode.wire, expected['stockMode']);
        expect(result.stockLevel?.wire, expected['stockLevel']);
        expect(result.quantity, expected['quantity']);
        expect(result.target, expected['target']);
      });
    }
  });

  group('expiryStatus', () {
    for (final v in group_('expiryStatus')) {
      test(v['name'], () {
        final result = evaluateExpiry(
          fields(v['item'] as Map<String, dynamic>),
          v['leadDays'] as int,
          v['today'] as int,
        );
        expect(result.wire, v['expiryStatus']);
      });
    }
  });

  group('stepping on hand', () {
    test('steps down to zero and keeps the words', () {
      expect(stepQuantity('1 eggs', -1), '0 eggs');
      expect(stepQuantity('4 eggs', 1), '5 eggs');
    });
  });

  test('formatNumber drops float noise', () {
    expect(formatNumber(1.2 - 1.1), '0.1');
    expect(formatNumber(8.0), '8');
    expect(formatNumber(2.5), '2.5');
  });

  test('addDays lands on midnight across months', () {
    final jan31 = todayEpoch(DateTime(2026, 1, 31, 15));
    final feb2 = DateTime.fromMillisecondsSinceEpoch(addDays(jan31, 2) * 1000);
    expect(feb2, DateTime(2026, 2, 2));
  });
}
