import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/theme/app_theme.dart';

void main() {
  const seed = Color(0xFF0082C9);

  group('buildAppTheme', () {
    test('carries the surfaces derived from its own scheme', () {
      for (final brightness in Brightness.values) {
        final theme = buildAppTheme(seed, brightness);
        final surfaces = theme.extension<AppSurfaces>()!;
        expect(surfaces.fill, theme.colorScheme.surfaceContainer);
        expect(surfaces.edge, theme.colorScheme.outlineVariant);
        expect(surfaces.onAccent, theme.colorScheme.onPrimary);
      }
    });

    test('keeps the seed as the accent', () {
      expect(buildAppTheme(seed, Brightness.dark).colorScheme.primary, seed);
    });

    test('ink on the accent follows the accent, not the brightness', () {
      for (final brightness in Brightness.values) {
        expect(
          buildAppTheme(seed, brightness).colorScheme.onPrimary,
          Colors.white,
        );
        expect(
          buildAppTheme(
            const Color(0xFFFFEB3B),
            brightness,
          ).colorScheme.onPrimary,
          Colors.black,
        );
      }
    });

    test('fields share the card radius and take the accent when focused', () {
      final border = buildAppTheme(
        seed,
        Brightness.light,
      ).inputDecorationTheme.border!;
      final resting =
          WidgetStateProperty.resolveAs<InputBorder>(border, {})
              as OutlineInputBorder;
      final focused =
          WidgetStateProperty.resolveAs<InputBorder>(border, {
                WidgetState.focused,
              })
              as OutlineInputBorder;
      expect(resting.borderRadius, BorderRadius.circular(SurfaceRadius.card));
      expect(focused.borderSide.color, seed);
    });

    test('a borderless field stays borderless in every state', () {
      final theme = buildAppTheme(seed, Brightness.light);
      final decoration = const InputDecoration.collapsed(
        hintText: '',
      ).applyDefaults(theme.inputDecorationTheme);
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, isNull);
      expect(decoration.focusedBorder, isNull);
    });
  });

  group('AppSurfaces', () {
    testWidgets('falls back to the ambient scheme without the extension', (
      tester,
    ) async {
      late AppSurfaces surfaces;
      late ColorScheme cs;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              surfaces = AppSurfaces.of(context);
              cs = Theme.of(context).colorScheme;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(surfaces.accent, cs.primary);
      expect(surfaces.raised, cs.surfaceContainerHighest);
    });

    test('a focused card and a selected row take the accent edge', () {
      final surfaces = AppSurfaces.fromScheme(
        ColorScheme.fromSeed(seedColor: seed),
      );
      for (final deco in [
        surfaces.card(focused: true),
        surfaces.row(selected: true),
      ]) {
        final side = (deco.border! as Border).top;
        expect(side.color, surfaces.accent);
        expect(side.width, 1.5);
      }
    });

    test('lerps between light and dark', () {
      final light = buildAppTheme(
        seed,
        Brightness.light,
      ).extension<AppSurfaces>()!;
      final dark = buildAppTheme(
        seed,
        Brightness.dark,
      ).extension<AppSurfaces>()!;
      expect(light.lerp(dark, 0).base, light.base);
      expect(light.lerp(dark, 1).base, dark.base);
    });
  });
}
