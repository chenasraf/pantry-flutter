import 'package:flutter/material.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/checklist_service.dart';

import '../widgets/preview_image.dart';

/// The photo attached to an item, at the size the surface drawing it needs.
///
/// The item carries the file and its owner rather than a URL, because the
/// preview endpoint is asked for one size at a time and every surface wants a
/// different one.
class ItemImage extends StatelessWidget {
  final ListItem item;
  final int houseId;
  final int size;
  final BoxFit fit;
  final Widget? unavailable;

  const ItemImage({
    super.key,
    required this.item,
    required this.houseId,
    required this.size,
    this.fit = BoxFit.cover,
    this.unavailable,
  });

  @override
  Widget build(BuildContext context) => PreviewImage(
    source: () => ChecklistService.instance.itemImagePreviewUri(
      houseId,
      item.imageFileId!,
      item.imageUploadedBy ?? '',
      size: size,
    ),
    fit: fit,
    unavailable: unavailable,
  );
}
