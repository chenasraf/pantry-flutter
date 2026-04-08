import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final String imageUrl;
  final Map<String, String> headers;
  final String heroTag;

  const ImagePreview({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.headers = const {},
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
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
          heroTag: heroTag,
          headers: headers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Center(
            child: Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                headers: headers,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
