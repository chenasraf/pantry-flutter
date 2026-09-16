import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/widgets/avif_image.dart';
import 'package:pantry/widgets/image_preview.dart';

/// An item's picture at row size. Shared by the checklist row and the shopping
/// row so a photographed item is recognisable in the aisle by the same square
/// it is recognised by on the list.
class ItemThumb extends StatelessWidget {
  final int houseId;

  /// The server's copy, once it has one.
  final int? fileId;
  final String owner;

  /// The copy the queue is still holding. Takes precedence over [fileId]: it
  /// is the picture the user chose most recently, and while it waits the
  /// server's is either absent or the one being replaced.
  final File? pending;

  final double size;

  /// Tag the thumbnail flies under when a tap opens the picture full-screen.
  /// Null leaves the square inert so the whole row keeps the tap — what a row
  /// does with one (check off, toggle selection) is worth more than the
  /// picture when the row is in such a mode. Must be unique within a route.
  final String? previewHeroTag;

  const ItemThumb({
    super.key,
    required this.houseId,
    required this.fileId,
    required this.owner,
    this.pending,
    this.size = 40,
    this.previewHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.broken_image_outlined, size: 18),
    );
    final file = pending;
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    final Widget thumb;
    String? fullUrl;
    if (file != null) {
      thumb = AvifFileImage(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: fallback,
      );
    } else {
      thumb = AvifNetworkImage(
        imageUrl: ChecklistService.instance
            .itemImagePreviewUri(houseId, fileId!, owner, size: 96)
            .toString(),
        headers: headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: fallback,
      );
      fullUrl = ChecklistService.instance
          .itemImagePreviewUri(houseId, fileId!, owner, size: 2048)
          .toString();
    }

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: thumb,
    );

    final heroTag = previewHeroTag;
    if (heroTag == null) return clipped;

    return GestureDetector(
      onTap: () => ImagePreview.show(
        context,
        imageUrl: fullUrl,
        file: file,
        heroTag: heroTag,
        headers: headers,
      ),
      child: Hero(tag: heroTag, child: clipped),
    );
  }
}
