// Generates Android vector drawables for each checklist icon key, so the
// home-screen widget can render them. Source: Google Material Symbols
// (Apache-2.0). Run via `make widget-icons`.
//
// Keep [_materialNames] in sync with lib/utils/checklist_icons.dart — if a new
// icon key is added there, add the matching Material Symbols name here and
// re-run the script.

import 'dart:io';

import 'package:http/http.dart' as http;

// Map from checklist icon key (as stored on each list) to the Material Symbols
// icon name on GitHub.
const _materialNames = <String, String>{
  'clipboard-check': 'assignment_turned_in',
  'clipboard-list': 'assignment',
  'format-list-checks': 'checklist',
  'cart': 'shopping_cart',
  'basket': 'shopping_basket',
  'star': 'star',
  'heart': 'favorite',
  'home': 'home',
  'calendar': 'calendar_today',
  'bell': 'notifications',
  'flag': 'flag',
  'bookmark': 'bookmark',
  'pin': 'push_pin',
  'map-marker': 'location_on',
  'briefcase': 'work',
  'wrench': 'build',
  'silverware': 'restaurant',
  'coffee': 'coffee',
  'gift': 'redeem',
  'book': 'menu_book',
  'school': 'school',
  'palette': 'palette',
  'camera': 'photo_camera',
  'music': 'music_note',
  'gamepad': 'sports_esports',
  'run': 'directions_run',
  'dumbbell': 'fitness_center',
  'pill': 'medication',
  'paw': 'pets',
  'flower': 'local_florist',
  'tree': 'park',
  'broom': 'cleaning_services',
  'lightbulb': 'lightbulb',
  'package': 'inventory_2',
  'car': 'directions_car',
  'bike': 'directions_bike',
  'beach': 'beach_access',
  'tag': 'label',
};

// The default drawable used when a list has an icon key the widget doesn't
// know about — kept as `widget_icon_default.xml` so Kotlin can reference it
// statically.
const _defaultMaterialName = 'assignment_turned_in';

const _baseUrl =
    'https://raw.githubusercontent.com/google/material-design-icons/master/symbols/android';

Future<void> main() async {
  final outDir = Directory('android/app/src/main/res/drawable');
  if (!outDir.existsSync()) {
    stderr.writeln('${outDir.path} does not exist');
    exitCode = 1;
    return;
  }

  final all = <String, String>{
    ..._materialNames,
    '_default': _defaultMaterialName,
  };

  var failed = 0;
  for (final entry in all.entries) {
    final filename = entry.key == '_default'
        ? 'widget_icon_default.xml'
        : 'widget_icon_${entry.key.replaceAll('-', '_')}.xml';
    final name = entry.value;
    final url =
        '$_baseUrl/$name/materialsymbolsoutlined/${name}_fill1_24px.xml';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      stderr.writeln('FAIL ${res.statusCode}: $filename ($name)');
      failed++;
      continue;
    }
    // Strip `android:tint="?attr/colorControlNormal"` — that attr lives in
    // AppCompat themes and our widget context can't resolve it. We set the
    // tint at runtime via `setColorFilter` instead.
    final sanitized = res.body.replaceAll(
      RegExp(r'\s*android:tint="\?attr/colorControlNormal"'),
      '',
    );
    File('${outDir.path}/$filename').writeAsStringSync(sanitized);
    stdout.writeln('OK   $filename ($name)');
  }
  if (failed > 0) {
    stderr.writeln('$failed icon(s) failed to download');
    exitCode = 1;
  }
}
