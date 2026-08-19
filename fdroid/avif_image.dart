import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// F-Droid variant of lib/widgets/avif_image.dart.
//
// The default build uses `flutter_avif` to decode AVIF images, but that package
// ships prebuilt native blobs (libflutter_avif.so, wasm) with no buildable
// source, so F-Droid's scanner strips them and the reproducible-build check
// fails. This drop-in replacement exposes the same public API but decodes with
// Flutter's built-in codecs only (JPEG/PNG/WebP/GIF). AVIF originals won't
// render on the F-Droid build; Nextcloud's preview endpoint transcodes to JPEG,
// so the common case is unaffected. Keep this in sync with the real widget's
// public surface — tool/fdroid/apply.sh copies it over the real one.

/// [ImageProvider] that displays a remote image, disk-cached via
/// [DefaultCacheManager] to match cached_network_image.
class AvifAwareNetworkImage extends ImageProvider<AvifAwareNetworkImage> {
  const AvifAwareNetworkImage(
    this.url, {
    this.scale = 1.0,
    this.headers = const {},
  });

  final String url;
  final double scale;
  final Map<String, String> headers;

  @override
  Future<AvifAwareNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AvifAwareNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AvifAwareNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      chunkEvents: chunkEvents.stream,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Url: ${key.url}'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AvifAwareNetworkImage key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      final requestHeaders = <String, String>{};
      headers.forEach((name, value) {
        requestHeaders[name.toLowerCase()] = value;
      });

      final stream = DefaultCacheManager().getImageFile(
        url,
        headers: requestHeaders,
        withProgress: true,
      );

      Uint8List? bytes;
      await for (final event in stream) {
        if (event is DownloadProgress) {
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: event.downloaded,
              expectedTotalBytes: event.totalSize,
            ),
          );
        } else if (event is FileInfo) {
          bytes = await event.file.readAsBytes();
          break;
        }
      }

      if (bytes == null || bytes.isEmpty) {
        PaintingBinding.instance.imageCache.evict(key);
        throw StateError('$url is empty and cannot be loaded as an image.');
      }

      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AvifAwareNetworkImage &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AvifAwareNetworkImage')}("$url", scale: $scale)';
}

/// [ImageProvider] for in-memory bytes (e.g. a just-picked file shown before
/// upload).
class AvifAwareMemoryImage extends ImageProvider<AvifAwareMemoryImage> {
  const AvifAwareMemoryImage(this.bytes, {this.scale = 1.0});

  final Uint8List bytes;
  final double scale;

  @override
  Future<AvifAwareMemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AvifAwareMemoryImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AvifAwareMemoryImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'AvifAwareMemoryImage(${describeIdentity(key.bytes)})',
    );
  }

  Future<ui.Codec> _loadAsync(
    AvifAwareMemoryImage key,
    ImageDecoderCallback decode,
  ) async {
    return decode(await ui.ImmutableBuffer.fromUint8List(key.bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AvifAwareMemoryImage &&
        identical(other.bytes, bytes) &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(identityHashCode(bytes), scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AvifAwareMemoryImage')}(${describeIdentity(bytes)}, scale: $scale)';
}

/// [ImageProvider] for a local file (e.g. a just-picked image previewed before
/// upload).
class AvifAwareFileImage extends ImageProvider<AvifAwareFileImage> {
  const AvifAwareFileImage(this.file, {this.scale = 1.0});

  final File file;
  final double scale;

  @override
  Future<AvifAwareFileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AvifAwareFileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AvifAwareFileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.file.path,
    );
  }

  Future<ui.Codec> _loadAsync(
    AvifAwareFileImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.file.readAsBytes();
    if (bytes.isEmpty) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('${key.file.path} is empty and cannot be loaded.');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AvifAwareFileImage &&
        other.file.path == file.path &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(file.path, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AvifAwareFileImage')}("${file.path}", scale: $scale)';
}

Widget _fadeIn(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    child: child,
  );
}

/// Displays a remote image, mirroring the subset of [Image]/CachedNetworkImage
/// properties the app relies on.
class AvifNetworkImage extends StatelessWidget {
  const AvifNetworkImage({
    super.key,
    required this.imageUrl,
    this.headers = const {},
    this.fit,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String imageUrl;
  final Map<String, String> headers;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AvifAwareNetworkImage(imageUrl, headers: headers),
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      frameBuilder: _fadeIn,
      errorBuilder: errorWidget == null
          ? null
          : (context, error, stackTrace) => errorWidget!,
    );
  }
}

/// Displays in-memory image bytes.
class AvifMemoryImage extends StatelessWidget {
  const AvifMemoryImage(
    this.bytes, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.opacity,
  });

  final Uint8List bytes;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Animation<double>? opacity;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AvifAwareMemoryImage(bytes),
      fit: fit,
      width: width,
      height: height,
      opacity: opacity,
      gaplessPlayback: true,
    );
  }
}
