import 'dart:io';

/// Replaces YAML unicode escape sequences (\uXXXX, \xXX) with actual UTF-8
/// characters in all messages*.i18n.yaml files.
void main() {
  final yamlFiles = Directory('lib').listSync().whereType<File>().where(
    (f) => RegExp(r'messages.*\.i18n\.yaml$').hasMatch(f.path),
  );

  final uEscape = RegExp(r'\\u([0-9a-fA-F]{4})');
  final xEscape = RegExp(r'\\x([0-9a-fA-F]{2})');

  for (final file in yamlFiles) {
    var content = file.readAsStringSync();
    final original = content;

    content = content.replaceAllMapped(
      uEscape,
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    content = content.replaceAllMapped(
      xEscape,
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed: ${file.path}');
    }
  }
}
