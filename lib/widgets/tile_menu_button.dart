import 'package:flutter/material.dart';

class TileMenuButton extends StatelessWidget {
  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String> onSelected;

  const TileMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 4)],
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: onSelected,
      itemBuilder: (_) => items,
    );
  }
}
