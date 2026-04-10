import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/models/photo.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

class PhotoDetailView extends StatelessWidget {
  final Photo photo;
  final Uri imageUri;
  final Map<String, String> headers;
  final PhotoBoardController controller;

  const PhotoDetailView({
    super.key,
    required this.photo,
    required this.imageUri,
    required this.headers,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(photo.caption ?? '')),
      body: InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUri.toString(),
            httpHeaders: headers,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, size: 64),
          ),
        ),
      ),
    );
  }
}
