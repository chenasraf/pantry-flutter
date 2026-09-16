import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/widgets/avif_image.dart';

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

  const ItemThumb({
    super.key,
    required this.houseId,
    required this.fileId,
    required this.owner,
    this.pending,
    this.size = 40,
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
    if (file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AvifFileImage(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: fallback,
        ),
      );
    }
    final uri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      fileId!,
      owner,
      size: 96,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AvifNetworkImage(
        imageUrl: uri.toString(),
        headers: headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: fallback,
      ),
    );
  }
}
