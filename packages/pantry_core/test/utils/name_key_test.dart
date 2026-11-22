import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/name_key.dart';

/// The cases are a copy of the server's tests/fixtures/name-key-cases.json,
/// which the server and the web client run too.
void main() {
  final cases =
      (jsonDecode(File('test/fixtures/name-key-cases.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  for (final c in cases) {
    final name = c['name'] as String;
    test('folds ${jsonEncode(name)}', () {
      expect(nameKey(name), c['key']);
    });
  }
}
