import 'package:unorm_dart/unorm_dart.dart' as unorm;

final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);
final _innermostParenthetical = RegExp(r'\s*\([^()]*\)');
final _whitespace = RegExp(r'\s+');

/// The key item memory files a name under, so "Milk", "milk " and "Milk (2%)"
/// share what the household picked for them.
///
/// The server folds names the same way and owns the rules; every case in
/// `test/fixtures/name-key-cases.json` is a copy of the server's and must
/// fold identically here. An empty key is never stored or looked up.
String nameKey(String name) {
  var key = unorm.nfd(name).replaceAll(_combiningMarks, '');

  // Innermost parentheses first, so nested ones go too.
  String before;
  do {
    before = key;
    key = key.replaceAll(_innermostParenthetical, '');
  } while (key != before);

  final comma = key.indexOf(',');
  if (comma != -1) key = key.substring(0, comma);

  return key.toLowerCase().replaceAll(_whitespace, ' ').trim();
}
