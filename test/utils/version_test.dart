import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/version.dart';

void main() {
  group('Version.parse', () {
    test('parses standard dotted versions', () {
      expect(Version.parse('34.0.1').parts, [34, 0, 1]);
      expect(Version.parse('0.14.0').parts, [0, 14, 0]);
    });

    test('strips leading v and trailing pre-release', () {
      expect(Version.parse('v1.2.3').parts, [1, 2, 3]);
      expect(Version.parse('0.14.0-beta.2').parts, [0, 14, 0]);
    });

    test('tryParse returns null on garbage', () {
      expect(Version.tryParse(null), isNull);
      expect(Version.tryParse('nope'), isNull);
    });
  });

  group('Version.satisfies', () {
    final v = Version.parse('34.0.1');

    test('>= / <=', () {
      expect(v.satisfies('>=', Version.parse('34.0.0')), isTrue);
      expect(v.satisfies('>=', Version.parse('34.0.1')), isTrue);
      expect(v.satisfies('>=', Version.parse('34.0.2')), isFalse);
      expect(v.satisfies('<=', Version.parse('34.0.1')), isTrue);
      expect(v.satisfies('<=', Version.parse('33.9.9')), isFalse);
    });

    test('> / <', () {
      expect(v.satisfies('>', Version.parse('34.0.0')), isTrue);
      expect(v.satisfies('>', Version.parse('34.0.1')), isFalse);
      expect(v.satisfies('<', Version.parse('34.0.2')), isTrue);
    });

    test('== / !=', () {
      expect(v.satisfies('==', Version.parse('34.0.1')), isTrue);
      expect(v.satisfies('==', Version.parse('34.0.0')), isFalse);
      expect(v.satisfies('!=', Version.parse('34.0.0')), isTrue);
    });

    test('treats missing trailing segments as zero', () {
      expect(
        Version.parse('34').satisfies('==', Version.parse('34.0.0')),
        isTrue,
      );
      expect(
        Version.parse('34.1').satisfies('>', Version.parse('34.0.9')),
        isTrue,
      );
    });

    test('rejects unsupported operator', () {
      expect(
        () => v.satisfies('~>', Version.parse('34.0.0')),
        throwsArgumentError,
      );
    });
  });
}
