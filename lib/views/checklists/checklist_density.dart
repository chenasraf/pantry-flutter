/// Vertical density of checklist rows, chosen in Settings. Each level carries
/// the concrete layout metrics (row padding, checkbox tap height, swipe-action
/// sizing) so the row and swipe widgets stay declarative instead of branching
/// on a string. Adding a level is a matter of adding an enum entry.
enum ChecklistDensity {
  /// Generous spacing — the default.
  normal(
    rowPadV: 13,
    metaGap: 5,
    checkboxHitHeight: 48,
    overflowIconSize: 24,
    swipeActionWidth: 62,
    swipeIconSize: 20,
    swipeLabelGap: 4,
    swipeFontSize: 10,
  ),

  /// Trimmed padding and tap targets to fit more items on screen.
  dense(
    rowPadV: 6,
    metaGap: 3,
    checkboxHitHeight: 40,
    overflowIconSize: 20,
    swipeActionWidth: 52,
    swipeIconSize: 17,
    swipeLabelGap: 2,
    swipeFontSize: 9,
  ),

  /// Squeezes out the last few vertical pixels — smallest padding and row
  /// height while keeping text and controls large enough to stay usable.
  compact(
    rowPadV: 3,
    metaGap: 2,
    checkboxHitHeight: 34,
    overflowIconSize: 20,
    swipeActionWidth: 48,
    swipeIconSize: 16,
    swipeLabelGap: 2,
    swipeFontSize: 9,
  );

  const ChecklistDensity({
    required this.rowPadV,
    required this.metaGap,
    required this.checkboxHitHeight,
    required this.overflowIconSize,
    required this.swipeActionWidth,
    required this.swipeIconSize,
    required this.swipeLabelGap,
    required this.swipeFontSize,
  });

  /// Vertical padding above and below each row's content.
  final double rowPadV;

  /// Gap between the item title and its meta chip row.
  final double metaGap;

  /// Height of the leading checkbox's tap target. The 24px box is centered
  /// within it; shorter heights let single-line rows pack tighter.
  final double checkboxHitHeight;

  /// Size of the trailing overflow-menu icon (swipe actions turned off).
  final double overflowIconSize;

  /// Width of each revealed swipe action button.
  final double swipeActionWidth;

  /// Icon size within a swipe action button.
  final double swipeIconSize;

  /// Gap between a swipe action's icon and its label.
  final double swipeLabelGap;

  /// Font size of a swipe action's label.
  final double swipeFontSize;

  /// The persisted preference string this level maps to.
  static ChecklistDensity fromPref(String value) => switch (value) {
    'dense' => ChecklistDensity.dense,
    'compact' => ChecklistDensity.compact,
    _ => ChecklistDensity.normal,
  };
}
