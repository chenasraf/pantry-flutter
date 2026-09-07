import 'package:flutter/material.dart';

import 'services/wear_ambient.dart';

/// Drains the colour out of every pixel, whatever drew it.
///
/// A theme reaches widgets that read it; a photo, an avatar and a list's own
/// accent do not. The filter is what makes "no colour in ambient" true of the
/// screen rather than of the parts of it that happened to ask.
const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// How far content moves to keep a still screen from being retained by the
/// panel. Small enough not to reflow a layout, large enough to matter over the
/// hours a watch spends dimmed on a wrist.
const _burnInShift = 4.0;

/// Whether the screen being built is the dimmed one.
///
/// It rides the theme because the watch draws its own chrome — a card, a pill,
/// a rail — with [BoxDecoration] rather than with Material widgets, so a
/// [ThemeData] override reaches almost none of it. Those call sites ask this
/// instead, and being an inherited value is what rebuilds them when the wrist
/// drops.
@immutable
class WearAmbientTheme extends ThemeExtension<WearAmbientTheme> {
  const WearAmbientTheme({required this.isAmbient, required this.outline});

  final bool isAmbient;

  /// The edge a filled shape is reduced to.
  final Color outline;

  static WearAmbientTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<WearAmbientTheme>();

  static bool isAmbientIn(BuildContext context) =>
      maybeOf(context)?.isAmbient ?? false;

  @override
  WearAmbientTheme copyWith({bool? isAmbient, Color? outline}) =>
      WearAmbientTheme(
        isAmbient: isAmbient ?? this.isAmbient,
        outline: outline ?? this.outline,
      );

  /// Ambient is entered and left, never approached: a half-dimmed frame is not
  /// a state the watch has.
  @override
  WearAmbientTheme lerp(ThemeExtension<WearAmbientTheme>? other, double t) =>
      t < 0.5 ? this : (other as WearAmbientTheme? ?? this);
}

/// A filled shape interactively, its own outline once the screen dims.
///
/// The watch's chrome is hand-drawn, so "less fill, more outline" cannot be a
/// theme override — it has to be something each shape asks for. Passing the
/// interactive fill keeps that the single source of truth: the shape stays one
/// declaration, and the dimmed form is derived rather than maintained beside it.
BoxDecoration wearAmbientFill(
  BuildContext context, {
  required Color? color,
  required BorderRadiusGeometry borderRadius,
}) {
  final ambient = WearAmbientTheme.maybeOf(context);
  if (ambient == null || !ambient.isAmbient) {
    return BoxDecoration(color: color, borderRadius: borderRadius);
  }
  return BoxDecoration(
    borderRadius: borderRadius,
    border: Border.all(color: ambient.outline),
  );
}

/// The dimmed face of the watch app: the screen that was already there, drawn
/// for a display that is on but asleep.
///
/// It is a treatment rather than a second set of screens, which is what keeps
/// the wearer's place. Glancing down mid-shop shows the list they were on, in
/// grey, and raising the wrist brings the same list back in colour — nothing is
/// navigated and nothing is rebuilt underneath.
class WearAmbientSkin extends StatefulWidget {
  const WearAmbientSkin({super.key, required this.child});

  final Widget child;

  @override
  State<WearAmbientSkin> createState() => _WearAmbientSkinState();
}

class _WearAmbientSkinState extends State<WearAmbientSkin> {
  final _ambient = WearAmbient.instance;

  /// Advanced once per system update, and read only for its parity — the
  /// content sits one notch off-centre or the other, alternating, so no pixel
  /// holds the same value for long.
  int _updates = 0;

  @override
  void initState() {
    super.initState();
    _ambient.addListener(_onAmbient);
  }

  @override
  void dispose() {
    _ambient.removeListener(_onAmbient);
    super.dispose();
  }

  void _onAmbient() {
    if (!mounted) return;
    setState(() => _updates++);
  }

  /// The interactive theme with everything that costs light taken out of it:
  /// surfaces go black, the accent gives way to white, and the shapes that were
  /// filled become outlines.
  ThemeData _dim(ThemeData base) {
    const ink = Colors.white;
    final scheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: ink,
      onPrimary: Colors.black,
      secondary: ink,
      surface: Colors.black,
      onSurface: ink,
      surfaceContainerHighest: Colors.black,
      outline: ink,
    );
    final border = BorderSide(color: ink.withValues(alpha: 0.7));
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      dividerColor: ink.withValues(alpha: 0.4),
      dividerTheme: DividerThemeData(color: ink.withValues(alpha: 0.4)),
      // Every container that carried a tint becomes its own edge instead.
      cardTheme: base.cardTheme.copyWith(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.black,
        selectedColor: Colors.black,
        side: border,
        labelStyle: TextStyle(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: ink,
          elevation: 0,
          side: border,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: ink,
          elevation: 0,
          side: border,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: ink, side: border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ink),
      iconTheme: IconThemeData(color: ink),
      // What the hand-drawn chrome reads. The Material overrides above only
      // reach the widgets that ask a theme for their fill, which on this watch
      // is very few of them.
      extensions: [
        WearAmbientTheme(isAmbient: true, outline: ink.withValues(alpha: 0.7)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _ambient.state;
    if (!state.isAmbient) return widget.child;

    final shift = state.burnInProtectionRequired
        ? Offset(0, _updates.isEven ? -_burnInShift : _burnInShift)
        : Offset.zero;

    return Theme(
      data: _dim(Theme.of(context)),
      child: ColorFiltered(
        colorFilter: _greyscale,
        child: Transform.translate(offset: shift, child: widget.child),
      ),
    );
  }
}
