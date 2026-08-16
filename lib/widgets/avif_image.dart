import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Decodes the [bytes] into an [AvifCodec], transparently handling AVIF and any
/// format Flutter decodes natively (JPEG/PNG/WebP/GIF).
///
/// The server's preview endpoint returns a transcoded JPEG when Nextcloud can
/// generate a preview, but falls back to the original file otherwise — which
/// may be an AVIF that Flutter's own decoder cannot read. Sniffing the bytes
/// lets a single provider serve both cases.
Future<AvifCodec> _codecForBytes(
  Uint8List bytes,
  ImageDecoderCallback decode,
  int codecKey,
) async {
  final head = bytes.length >= 16 ? bytes.sublist(0, 16) : bytes;
  final type = isAvifFile(head);
  if (type != AvifFileType.unknown) {
    final codec = type == AvifFileType.avif
        ? SingleFrameAvifCodec(bytes: bytes)
        : MultiFrameAvifCodec(key: codecKey, avifBytes: bytes);
    await codec.ready();
    return codec;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  return _NativeAvifCodec(await decode(buffer));
}

/// Adapts a [ui.Codec] to the [AvifCodec] interface so non-AVIF images can be
/// driven by the same [AvifImageStreamCompleter] as AVIF ones.
class _NativeAvifCodec implements AvifCodec {
  _NativeAvifCodec(this._codec);

  final ui.Codec _codec;

  @override
  int get frameCount => _codec.frameCount;

  // -1 lets the completer loop animated frames; static images short-circuit on
  // frameCount == 1 before this is consulted.
  @override
  int get durationMs => -1;

  @override
  Future<void> ready() async {}

  @override
  Future<AvifFrameInfo> getNextFrame() async {
    final frame = await _codec.getNextFrame();
    return AvifFrameInfo(image: frame.image, duration: frame.duration);
  }

  @override
  void dispose() => _codec.dispose();
}

/// [ImageProvider] that displays a remote image, decoding AVIF when the server
/// serves it and falling back to Flutter's native decoders otherwise. Bytes are
/// disk-cached via [DefaultCacheManager], matching cached_network_image.
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
    return AvifImageStreamCompleter(
      key: key,
      codec: _loadAsync(key, decode, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      chunkEvents: chunkEvents.stream,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Url: ${key.url}'),
      ],
    );
  }

  Future<AvifCodec> _loadAsync(
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

      return _codecForBytes(bytes, decode, key.hashCode);
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

/// [ImageProvider] for in-memory bytes that may be AVIF (e.g. a just-picked file
/// shown before upload).
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
    return AvifImageStreamCompleter(
      key: key,
      codec: _codecForBytes(key.bytes, decode, key.hashCode),
      scale: key.scale,
      debugLabel: 'AvifAwareMemoryImage(${describeIdentity(key.bytes)})',
    );
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

/// [ImageProvider] for a local file that may be AVIF (e.g. a just-picked image
/// previewed before upload).
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
    return AvifImageStreamCompleter(
      key: key,
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.file.path,
    );
  }

  Future<AvifCodec> _loadAsync(
    AvifAwareFileImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.file.readAsBytes();
    if (bytes.isEmpty) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('${key.file.path} is empty and cannot be loaded.');
    }
    return _codecForBytes(bytes, decode, key.hashCode);
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

/// Displays a remote image with AVIF support, mirroring the subset of
/// [Image]/CachedNetworkImage properties the app relies on.
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

/// Displays in-memory image bytes with AVIF support.
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
