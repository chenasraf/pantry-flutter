import 'package:flutter/material.dart';

/// Generic glyph for each domain entity — filter facets, compose chips, group
/// headers, manage/assign actions, and the fallback when an entity has no
/// custom icon of its own. A custom icon always overrides these.
abstract final class EntityIcons {
  static const category = Icons.label_outline;
  static const label = Icons.sell_outlined;
  static const store = Icons.storefront_outlined;
  static const price = Icons.attach_money;
}
