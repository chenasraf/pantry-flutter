/// The geometry and timings the watch's lists are drawn to, judged on a round
/// screen rather than derived.
///
/// They sit together because they are coupled: a card claims [itemExtent] less
/// [cardGap], the falloff is quoted in rows rather than pixels, and a header
/// deliberately costs well under a row.
class WearMetrics {
  const WearMetrics._();

  /// The extent one row occupies, gap included.
  static const double itemExtent = 54;

  /// Between one card and the next. The card fills the rest of its row extent
  /// rather than sizing to its content: on a fixed-extent list the slack a card
  /// gives up becomes a gap, not a tighter list.
  static const double cardGap = 5;

  /// The drawn height of a card, as opposed to the row extent it sits in.
  static const double cardHeight = itemExtent - cardGap;

  /// A group header, deliberately well under a row.
  static const double headerExtent = 24;

  /// How far the focus falloff reaches, in rows.
  static const double falloffRows = 2.2;

  /// Fraction of the width held back at each side. The falloff's width factor
  /// is 1.0 on the centre line, so without this the focused row runs to the
  /// glass and a round bezel shaves its corners.
  static const double sideInset = 0.025;

  /// How long a check sits reversible before it is written.
  static const Duration undoWindow = Duration(milliseconds: 2000);

  /// Input is held for this long after the pager swaps between browse and a
  /// session, so a tap already descending cannot land on a page set that did
  /// not exist when the finger started moving.
  static const Duration modeLockout = Duration(milliseconds: 450);

  /// How often the watch re-reads what it is showing. Watch-local and fixed:
  /// the phone's interval describes a device that is not on a wrist.
  static const Duration pollInterval = Duration(seconds: 60);
}
