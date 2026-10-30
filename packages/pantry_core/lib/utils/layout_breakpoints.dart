/// List rows at most this many logical pixels wide use the compact layout.
/// Measured on the list pane itself, not the window or the platform, so a
/// landscape phone, a tablet split view and a resized desktop window each pick
/// by the space the row actually has.
const double kNarrowListPaneWidth = 600;

bool isNarrowListPane(double width) => width <= kNarrowListPaneWidth;
