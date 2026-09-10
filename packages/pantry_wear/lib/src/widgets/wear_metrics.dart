import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../wear_shape.dart';

/// The geometry and timings the watch's lists are drawn to, judged on a round
/// screen rather than derived.
///
/// The lengths sit together because they are coupled: a card claims
/// [itemExtent] less [cardGap], the falloff is quoted in rows rather than
/// pixels, and a header deliberately costs well under a row.
///
/// They are read through [of] rather than written down as constants because
/// every one of them is a measurement of *text*: a row is a line of it plus the
/// space around the line, and a wearer who asked the system for larger type
/// asked for a taller row along with it. Held at the size they were drawn at,
/// a scaled line runs out through the bottom of its own card and the wearer
/// reads neither.
class WearMetrics {
  /// What every length here is multiplied by.
  ///
  /// Never below 1: a smaller system font leaves the geometry alone, because a
  /// target is aimed at with a fingertip and a fingertip does not shrink with
  /// the type.
  final double scale;

  const WearMetrics._(this.scale);

  /// The geometry at the size it was drawn, for the few places that measure
  /// before there is a context to measure against.
  static const WearMetrics unscaled = WearMetrics._(1);

  /// The wearer's font size, sampled at the size a row's label is set in.
  ///
  /// Sampled rather than read off a factor: a scaler need not be linear, and
  /// what a row has to fit is what happens to *its* line, not what happens to
  /// a nominal one.
  static double scaleOf(BuildContext context) {
    const sample = 14.0;
    return math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(sample) / sample,
    );
  }

  static WearMetrics of(BuildContext context) =>
      WearMetrics._(scaleOf(context));

  /// What the rail takes off the top of the screen.
  ///
  /// The rail overlays the list rather than sitting above it, so this is also
  /// the space a page underneath has to hold back before its first row — on a
  /// round screen the half-viewport lead already clears it, but a flat list
  /// starts at the top and would draw its first row behind the rail.
  ///
  /// Capped, unlike the lengths below it: this one is a share of the screen
  /// rather than a measurement of a line, and a share that grows without limit
  /// is a rail with no list left under it.
  double railHeight(double viewportHeight) => math.min(
    viewportHeight * (WearShape.isRound ? 0.21 : 0.15) * scale,
    viewportHeight * 0.35,
  );

  /// The extent one row occupies, gap included.
  double get itemExtent => 54 * scale;

  /// Between one card and the next. The card fills the rest of its row extent
  /// rather than sizing to its content: on a fixed-extent list the slack a card
  /// gives up becomes a gap, not a tighter list.
  double get cardGap => 5 * scale;

  /// The drawn height of a card, as opposed to the row extent it sits in.
  double get cardHeight => itemExtent - cardGap;

  /// The radius that makes a card a pill on round glass: at a card's corners
  /// the bezel is already curving away, so following it beats fighting it. A
  /// square watch keeps the rectangle it shares an edge with.
  double get cardRadius => WearShape.isRound ? cardHeight / 2 : 14;

  /// A group header, deliberately well under a row.
  double get headerExtent => 24 * scale;

  /// One bought item on the trip summary. Shorter than a header because a
  /// trip has many of them and none is a target — they are what the summary
  /// says, not what it offers.
  double get summaryLineExtent => 20 * scale;

  /// The rail's second line: the group label, or the degraded state that
  /// outranks it. Deliberately shallow — it is a label, not a target.
  double get railLineExtent => 13 * scale;

  /// A rail button, at the size a wearer actually aims at. The expansion is a
  /// panel dropped below the rail rather than a slot inside it, so it takes the
  /// height it needs and covers the list — which the list can afford and a
  /// 13-pixel button cannot.
  double get railButtonExtent => 42 * scale;

  /// The radius that makes a rail button a pill on round glass.
  double get railButtonRadius => WearShape.isRound ? railButtonExtent / 2 : 14;

  /// Between the two buttons in the panel.
  double get railButtonGap => 6 * scale;

  /// Between the rail's own last line and the panel under it.
  double get railPanelGap => 8 * scale;

  /// A row of two photo tiles. Taller than a checklist card because a tile is
  /// the content rather than a label for it.
  ///
  /// A tile is a picture rather than a line, so it grows by less than the type
  /// does — enough for the caption riding it, not enough to cost the wearer
  /// the second tile.
  double get photoRowExtent => 88 * (1 + (scale - 1) / 2);

  /// Between the two tiles in a photo row.
  static const double photoTileGap = 6;

  /// A note on the wall. Taller than a checklist card because a card carries a
  /// title over either a progress bar or two lines of preview.
  double get noteRowExtent => 72 * scale;

  /// The drawn height of a note card, as opposed to the row extent it sits in.
  double get noteCardHeight => 66 * scale;

  /// How far the focus falloff reaches, in rows.
  static const double falloffRows = 2.2;

  /// Fraction of the width held back at each side. The falloff's width factor
  /// is 1.0 on the centre line, so without this the focused row runs to the
  /// glass and a round bezel shaves its corners.
  static const double sideInset = 0.025;

  /// What a page of prose is held back by on every side.
  ///
  /// A round screen is only ever as wide as its chord, so a page whose lines
  /// run the width of the viewport has their ends shaved wherever the circle
  /// has closed in — which is most of the screen, and all of the top and
  /// bottom. The band is the largest rectangle the circle holds: inside it a
  /// line is whole at any height it comes to rest at, where a full-width line
  /// is whole only across the middle.
  ///
  /// A square screen gives up nothing to its shape and keeps a margin for the
  /// bezel and nothing more.
  ///
  /// Rows do not use this. They follow the bezel instead — narrowing with
  /// distance from the centre line — which buys back the width the band gives
  /// up and is what [SnapFocusList] exists to do.
  static EdgeInsetsDirectional bandInsets(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    // Half the diagonal of the inscribed square is the radius, so each side
    // gives up (1 - 1/sqrt(2)) / 2 of the diameter.
    final inset = side * (WearShape.isRound ? 0.1465 : 0.06);
    return EdgeInsetsDirectional.all(inset);
  }

  /// The inset a photo row takes instead of [sideInset]. A tile is tall
  /// enough that its corners sit well above and below the centre line, where a
  /// round screen has already narrowed, so it wants more of the width held
  /// back than a short card does.
  static const double tallSideInset = 0.05;

  /// Input is held for this long after the pager swaps between browse and a
  /// session, so a tap already descending cannot land on a page set that did
  /// not exist when the finger started moving.
  static const Duration modeLockout = Duration(milliseconds: 450);

  /// How long a snapshot's arrival counts as the phone actively pushing.
  static const Duration mirrorFreshFor = Duration(minutes: 3);

  /// What the read poll's interval is multiplied by while snapshots are
  /// arriving. Stretched, never stopped: the mirror is an accelerator, so
  /// leaning on it is a saving to take and never a dependency to acquire.
  static const int pollStretch = 3;
}
