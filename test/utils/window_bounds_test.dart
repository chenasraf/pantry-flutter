import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/window_bounds.dart';
import 'package:pantry_core/services/prefs_service.dart';

void main() {
  const primary = Rect.fromLTWH(0, 0, 1920, 1080);
  const secondary = Rect.fromLTWH(1920, 0, 2560, 1440);

  group('resolveWindowBounds', () {
    test('keeps a frame that sits on a display', () {
      const saved = Rect.fromLTWH(200, 150, 1000, 700);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary],
        ),
        saved,
      );
    });

    test('keeps a frame that hangs off the edge but stays reachable', () {
      const saved = Rect.fromLTWH(1500, 900, 1000, 700);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary],
        ),
        saved,
      );
    });

    test('keeps a frame on a secondary display', () {
      const saved = Rect.fromLTWH(2200, 300, 1000, 700);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary, secondary],
        ),
        saved,
      );
    });

    test('centres on primary when the display it lived on is gone', () {
      const saved = Rect.fromLTWH(2200, 300, 1000, 700);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary],
        ),
        const Rect.fromLTWH(460, 190, 1000, 700),
      );
    });

    test('centres when only an unreachable sliver overlaps', () {
      const saved = Rect.fromLTWH(-980, 200, 1000, 700);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary],
        ),
        const Rect.fromLTWH(460, 190, 1000, 700),
      );
    });

    test('shrinks a frame too big for the display it falls back to', () {
      const saved = Rect.fromLTWH(2200, 300, 2400, 1300);
      expect(
        resolveWindowBounds(
          saved: saved,
          primary: primary,
          displays: const [primary],
        ),
        primary,
      );
    });
  });

  group('window bounds codec', () {
    test('round-trips a frame through whole pixels', () {
      const bounds = Rect.fromLTWH(100.4, 200.6, 1000.2, 700.8);
      expect(encodeWindowBounds(bounds), '100,201,1000,701');
      expect(
        decodeWindowBounds('100,201,1000,701'),
        const Rect.fromLTWH(100, 201, 1000, 701),
      );
    });

    test('reads back a negative position on a display left of primary', () {
      expect(
        decodeWindowBounds('-1500,-200,1000,700'),
        const Rect.fromLTWH(-1500, -200, 1000, 700),
      );
    });

    test('rejects malformed, unusable and missing values', () {
      expect(decodeWindowBounds(null), isNull);
      expect(decodeWindowBounds(''), isNull);
      expect(decodeWindowBounds('100,200,1000'), isNull);
      expect(decodeWindowBounds('100,200,1000,700,extra'), isNull);
      expect(decodeWindowBounds('100,200,wide,700'), isNull);
      expect(decodeWindowBounds('100,200,0,0'), isNull);
      expect(decodeWindowBounds('100,200,1000,-700'), isNull);
    });
  });
}
