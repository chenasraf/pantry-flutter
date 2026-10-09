import 'package:flutter/material.dart';

/// Corner radii of the app's surfaces.
///
/// One value per surface rather than per call site: a field, a card and a
/// selectable row are the same shape, so a change to that shape is one edit.
abstract final class SurfaceRadius {
  /// Fields, cards, selectable rows and buttons.
  static const double card = 14;

  /// Chips, pills and small toggles.
  static const double chip = 9;

  /// Icon tiles, thumbnails and photo/note tiles.
  static const double tile = 12;

  /// Popup menus and dropdown panels.
  static const double menu = 20;

  /// The top corners of a sheet rising from the bottom edge.
  static const double sheet = 24;
}

/// The app's named surfaces.
///
/// Most of the app's chrome is drawn with [BoxDecoration] rather than with
/// Material widgets, so [ThemeData]'s component themes never reach it. Call
/// sites ask for a surface by role here instead, and it is this extension —
/// not the call site — that knows what a card or a chip looks like.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.base,
    required this.fill,
    required this.raised,
    required this.edge,
    required this.accent,
    required this.onAccent,
    required this.success,
  });

  factory AppSurfaces.fromScheme(ColorScheme cs) => AppSurfaces(
    base: cs.surface,
    fill: cs.surfaceContainer,
    raised: cs.surfaceContainerHighest,
    edge: cs.outlineVariant,
    accent: cs.primary,
    onAccent: cs.onPrimary,
    success: const Color(0xFF5FBF8A),
  );

  /// The page behind every surface.
  final Color base;

  /// A card or field sitting on [base].
  final Color fill;

  /// A neutral chip, banner or thumbnail placeholder that stands out from
  /// [fill].
  final Color raised;

  /// The resting outline of a card, field, chip or divider.
  final Color edge;

  final Color accent;
  final Color onAccent;

  /// Something completed: a checked item, a finished trip.
  final Color success;

  /// Falls back to deriving from the ambient [ColorScheme] so a widget pumped
  /// under a bare [MaterialApp] — a test, a widget-config engine — still draws.
  static AppSurfaces of(BuildContext context) => ofTheme(Theme.of(context));

  static AppSurfaces ofTheme(ThemeData theme) =>
      theme.extension<AppSurfaces>() ??
      AppSurfaces.fromScheme(theme.colorScheme);

  static BorderRadius _r(double r) => BorderRadius.circular(r);

  /// A field, picker or fact card. [focused] draws the accent edge a field
  /// takes while it is being edited.
  BoxDecoration card({bool focused = false}) => BoxDecoration(
    color: fill,
    border: Border.all(
      color: focused ? accent : edge,
      width: focused ? 1.5 : 1,
    ),
    borderRadius: _r(SurfaceRadius.card),
  );

  /// A row the user picks one of: a list in the switcher, a recurrence mode.
  BoxDecoration row({bool selected = false}) => BoxDecoration(
    color: selected ? accent.withValues(alpha: 0.1) : fill,
    border: Border.all(
      color: selected ? accent : edge,
      width: selected ? 1.5 : 1,
    ),
    borderRadius: _r(SurfaceRadius.card),
  );

  /// A chip or pill. Without a [tint] it is neutral; with one it carries that
  /// colour, edged in it fully once [selected].
  BoxDecoration chip({Color? tint, bool selected = false}) {
    if (tint == null) {
      return BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.14) : raised,
        border: Border.all(
          color: selected ? accent : edge,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: _r(SurfaceRadius.chip),
      );
    }
    return BoxDecoration(
      color: tint.withValues(alpha: 0.14),
      border: Border.all(
        color: selected ? tint : tint.withValues(alpha: 0.4),
        width: selected ? 1.5 : 1,
      ),
      borderRadius: _r(SurfaceRadius.chip),
    );
  }

  /// The tinted square behind an entity's icon. [bordered] for the larger
  /// tiles that head a form or a detail view.
  BoxDecoration iconTile(Color tint, {bool bordered = false}) => BoxDecoration(
    color: tint.withValues(alpha: 0.14),
    border: bordered ? Border.all(color: tint.withValues(alpha: 0.3)) : null,
    borderRadius: _r(SurfaceRadius.tile),
  );

  /// A thumbnail frame, filled while its image is missing or loading.
  BoxDecoration thumbnail() =>
      BoxDecoration(color: raised, borderRadius: _r(SurfaceRadius.tile));

  /// The gap a dragged tile will land in.
  BoxDecoration dropTarget() => BoxDecoration(
    color: accent.withAlpha(20),
    border: Border.all(color: accent, width: 2),
    borderRadius: _r(SurfaceRadius.tile),
  );

  /// The screen's main action.
  BoxDecoration primaryButton({bool raisedShadow = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent, accent.withValues(alpha: 0.8)],
    ),
    borderRadius: _r(SurfaceRadius.card),
    boxShadow: raisedShadow
        ? [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
  );

  /// The quiet action beside [primaryButton], such as Cancel.
  BoxDecoration secondaryButton() => card();

  /// A bar pinned to the bottom of a screen, holding its actions.
  BoxDecoration actionBar() => BoxDecoration(
    color: base,
    border: Border(top: BorderSide(color: edge.withValues(alpha: 0.5))),
  );

  /// A header pinned to the top of a scrolling section.
  BoxDecoration stickyHeader() => BoxDecoration(
    color: base,
    border: Border(bottom: BorderSide(color: edge)),
  );

  /// The grip at the top of a draggable sheet.
  BoxDecoration dragHandle() =>
      BoxDecoration(color: edge, borderRadius: BorderRadius.circular(3));

  /// The filled circle marking a picked row.
  BoxDecoration selectionDot() =>
      BoxDecoration(color: accent, shape: BoxShape.circle);

  @override
  AppSurfaces copyWith({
    Color? base,
    Color? fill,
    Color? raised,
    Color? edge,
    Color? accent,
    Color? onAccent,
    Color? success,
  }) => AppSurfaces(
    base: base ?? this.base,
    fill: fill ?? this.fill,
    raised: raised ?? this.raised,
    edge: edge ?? this.edge,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success ?? this.success,
  );

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      base: Color.lerp(base, other.base, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// The app's theme for [seed] in [brightness].
///
/// Material widgets read their look from the component themes here, and the
/// app's hand-drawn chrome reads [AppSurfaces], so both sides of the UI change
/// together.
ThemeData buildAppTheme(Color seed, Brightness brightness) {
  // The server's accent replaces the generated primary verbatim, so the ink on
  // it has to follow the accent too — the generated onPrimary was picked for a
  // tone the app never shows, and in dark mode it is near-black on a mid blue.
  final cs = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
      .copyWith(
        primary: seed,
        onPrimary: ThemeData.estimateBrightnessForColor(seed) == Brightness.dark
            ? Colors.white
            : Colors.black,
      );
  final surfaces = AppSurfaces.fromScheme(cs);

  OutlineInputBorder outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
        borderSide: BorderSide(color: color, width: width),
      );

  final menuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(SurfaceRadius.menu),
  );

  return ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    extensions: [surfaces],
    // Only `border`, resolved per state: a theme-level enabledBorder or
    // focusedBorder would outrank a field's own `InputBorder.none` and draw an
    // outline inside the borderless fields that sit in a card.
    inputDecorationTheme: InputDecorationTheme(
      border: WidgetStateInputBorder.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        if (states.contains(WidgetState.disabled)) {
          return outline(cs.outlineVariant.withValues(alpha: 0.5));
        }
        if (states.contains(WidgetState.error)) {
          return outline(cs.error, focused ? 1.5 : 1);
        }
        return focused ? outline(cs.primary, 1.5) : outline(cs.outlineVariant);
      }),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: menuShape,
      elevation: 8,
      position: PopupMenuPosition.under,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        elevation: const WidgetStatePropertyAll(3),
        shape: WidgetStatePropertyAll(menuShape),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SurfaceRadius.sheet),
        ),
      ),
    ),
  );
}
