// ignore_for_file: avoid_print
// A script that auto-populates a Pantry translation file based upon
// translations of the Nextcloud app. See usage instructions at the bottom of
// this file.
//
// i18n_generate_from_nextcloud.dart
// Copyright (C) Eskild Hustvedt 2026
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice (including the next
// paragraph) shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

var autoTranslated = 0;

// Recursively called subroutine that iterates through the translation tree
void replaceStringsRecursive(
  YamlEditor editor,
  YamlNode source,
  List<Object> path,
  Map<String, dynamic> nextcloudTranslations,
) {
  if (source is YamlMap) {
    for (final key in source.nodes.keys) {
      final value = source.nodes[key]!;
      replaceStringsRecursive(editor, value, [
        ...path,
        (key as YamlNode).value as Object,
      ], nextcloudTranslations);
    }
  } else if (source is YamlList) {
    for (var i = 0; i < source.nodes.length; i++) {
      replaceStringsRecursive(editor, source.nodes[i], [
        ...path,
        i,
      ], nextcloudTranslations);
    }
  } else {
    final original = (source.value.toString()).toLowerCase();
    final replacement = nextcloudTranslations[original];
    if (replacement != null && source.value != replacement) {
      editor.update(path, replacement);
      autoTranslated++;
    }
  }
}

// Output usage based on the documentation at the end of this file
void usage([String? msg, int exit = 0]) {
  if (msg != null) {
    stderr.write(msg);
  }
  print(r'''
i18n_generate_from_nextcloud.dart

This script lets you pull in translations from the Pantry Nextcloud app into a
translation file for the Flutter app, saving you time from having to do this
manually.

You run it like this: dart run tool/i18n_generate_from_nextcloud.dart
/path/to/nextcloud-pantry-git/l10n/LANG.json
./lib/i18n/messages_LANG.i18n.yaml. For instance if your language is nn, and
you have the nextcloud-pantry git repo checked out to ~/nextcloud-pantry then
the command becomes: dart run tool/i18n_generate_from_nextcloud.dart
~/nextcloud-pantry/l10n/nn_NO.json ./lib/i18n/messages_nn.i18n.yaml.

It will only update strings that are not translated already.
''');
  exitCode = exit;
}

// Main entry
void main(List<String> args) {
  if (args.isEmpty) {
    usage();
    return;
  }

  // The nextcloud JSON file
  final nextcloudFile = args.isNotEmpty ? args[0] : null;

  // The flutter YAML file
  final targetFile = args.length > 1 ? args[1] : null;

  // Validate args
  if (nextcloudFile == null || targetFile == null) {
    usage(
      'Error: You must specify both the path to a Nextcloud Pantry JSON-file and a Flutter Pantry YAML-file.\n',
      1,
    );
    return;
  }
  final ncFileObj = File(nextcloudFile);
  final targetFileObj = File(targetFile);
  if (!ncFileObj.existsSync()) {
    usage('Error: $nextcloudFile does not exist or is not readable\n', 1);
    return;
  }
  if (!targetFileObj.existsSync()) {
    usage('Error: $targetFile does not exist or is not readable\n', 1);
    return;
  }

  // Load the JSON file
  final ncData =
      jsonDecode(ncFileObj.readAsStringSync()) as Map<String, dynamic>;

  // Our YAML handler. yaml_edit performs surgical, in-place edits on the source
  // text, so the order and style of the original file are preserved and git
  // diffs are (mostly) correct.
  final editor = YamlEditor(targetFileObj.readAsStringSync());
  final yaml = loadYamlNode(targetFileObj.readAsStringSync());

  // Lowercase all source keys, so that casing in the English version between
  // flutter and Nextcloud are ignored
  final translations = <String, dynamic>{};
  final rawTranslations = ncData['translations'] as Map;
  for (final entry in rawTranslations.entries) {
    var src = entry.key as String;
    final target = entry.value;
    translations[src.toLowerCase()] = target;

    // Also add an alternative version without a leading .
    if (src.endsWith('.')) {
      src = src.substring(0, src.length - 1);
      translations[src.toLowerCase()] = target;
    }
  }

  // Perform the updates
  replaceStringsRecursive(editor, yaml, [], translations);

  // autoTranslated will be nonzero if we actually made any changes
  if (autoTranslated > 0) {
    targetFileObj.writeAsStringSync(editor.toString());
    print(
      'Done, wrote $targetFile. Used $autoTranslated translations from Nextcloud.',
    );
  } else {
    print('Nothing to update.');
  }
}
