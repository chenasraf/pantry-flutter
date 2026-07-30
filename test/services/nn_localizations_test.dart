import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pantry/services/nn_localizations.dart';

void main() {
  group('Nynorsk (nn) framework localizations', () {
    test('registerNnLocaleData makes nn a valid intl locale', () {
      registerNnLocaleData();
      expect(intl.DateFormat.localeExists('nn'), isTrue);
      // The crash path from flutter/flutter#66553: DateFormat('…', 'nn') used to
      // throw ArgumentError('Invalid locale "nn"'). It must not anymore.
      expect(() => intl.DateFormat.yMMMMEEEEd('nn'), returnsNormally);
    });

    test('nn date formatting uses Nynorsk weekday names', () {
      registerNnLocaleData();
      // 2024-01-01 is a Monday -> Nynorsk "måndag" (Bokmål would be "mandag").
      final date = DateTime(2024, 1, 1);
      expect(intl.DateFormat.EEEE('nn').format(date), 'måndag');
      // 2024-01-06 is a Saturday -> Nynorsk "laurdag" (Bokmål "lørdag").
      expect(
        intl.DateFormat.EEEE('nn').format(DateTime(2024, 1, 6)),
        'laurdag',
      );
    });

    test('material delegate loads and exposes Nynorsk strings', () async {
      final delegate = nnLocalizationsDelegates
          .whereType<LocalizationsDelegate<MaterialLocalizations>>()
          .single;
      expect(delegate.isSupported(const Locale('nn')), isTrue);
      final m = await delegate.load(const Locale('nn'));
      expect(m.selectAllButtonLabel, 'Vel alle');
      expect(m.moreButtonTooltip, 'Meir');
      expect(m.previousMonthTooltip, 'Førre månad');
      // Date helpers must not throw and should produce Nynorsk month text.
      expect(m.formatFullDate(DateTime(2024, 3, 5)), contains('mars'));
      expect(m.formatDecimal(1234), isNotEmpty);
    });

    test('cupertino delegate loads and exposes Nynorsk strings', () async {
      final delegate = nnLocalizationsDelegates
          .whereType<LocalizationsDelegate<CupertinoLocalizations>>()
          .single;
      expect(delegate.isSupported(const Locale('nn')), isTrue);
      final c = await delegate.load(const Locale('nn'));
      expect(c.selectAllButtonLabel, 'Vel alle');
      expect(c.todayLabel, 'I dag');
      expect(c.timerPickerHourLabel(2), 'timar');
    });
  });
}
