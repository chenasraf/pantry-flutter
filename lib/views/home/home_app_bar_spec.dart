import 'package:flutter/material.dart';

/// What a section wants the shared home AppBar to show while its tab is
/// active. Home owns the actual `AppBar` widget so the Scaffold's AppBar stays
/// the same instance across tab switches; a section just hands it the leading
/// / title / actions to display.
class HomeAppBarSpec {
  final Widget? leading;
  final double? leadingWidth;

  /// Null leaves the AppBar showing the section's own name.
  final Widget? title;
  final double? titleSpacing;

  /// Section-specific actions. Home appends its own home-level actions
  /// (notifications, user menu) after these.
  final List<Widget> actions;

  /// Whether home contributes its desktop refresh button. Sections that carry
  /// a refresh of their own among [actions] turn it off.
  final bool hostRefresh;

  const HomeAppBarSpec({
    this.leading,
    this.leadingWidth,
    this.title,
    this.titleSpacing,
    this.actions = const [],
    this.hostRefresh = true,
  });
}
