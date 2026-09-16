import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry_core/widgets/avif_image.dart';

class ImagePreview extends StatelessWidget {
  /// The image on the server. Ignored when [file] is set.
  final String? imageUrl;
  final Map<String, String> headers;

  /// A local image to show instead of [imageUrl] — an upload the sync queue is
  /// still holding, which the server has no copy of to serve.
  final File? file;

  final String heroTag;

  const ImagePreview({
    super.key,
    this.imageUrl,
    this.file,
    required this.heroTag,
    this.headers = const {},
  }) : assert(imageUrl != null || file != null, 'nothing to show');

  static void show(
    BuildContext context, {
    String? imageUrl,
    File? file,
    required String heroTag,
    Map<String, String> headers = const {},
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, _) => ImagePreview(
          imageUrl: imageUrl,
          file: file,
          heroTag: heroTag,
          headers: headers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const broken = Icon(
      Icons.broken_image_outlined,
      size: 64,
      color: Colors.white54,
    );
    final local = file;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: appBarBackLeading(context),
        ),
        body: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Center(
            child: Hero(
              tag: heroTag,
              child: local != null
                  ? AvifFileImage(
                      local,
                      fit: BoxFit.contain,
                      errorWidget: broken,
                    )
                  : AvifNetworkImage(
                      imageUrl: imageUrl!,
                      headers: headers,
                      fit: BoxFit.contain,
                      errorWidget: broken,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
