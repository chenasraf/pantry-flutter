import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/models/photo.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class PhotoDetailView extends StatefulWidget {
  final Photo photo;
  final int houseId;
  final Map<String, String> headers;
  final PhotoBoardController controller;

  const PhotoDetailView({
    super.key,
    required this.photo,
    required this.houseId,
    required this.headers,
    required this.controller,
  });

  @override
  State<PhotoDetailView> createState() => _PhotoDetailViewState();
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  static bool get _isDesktop =>
      kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  late PageController _pageController;
  late final FocusNode _focusNode;
  final Map<int, TransformationController> _transformControllers = {};
  final Map<int, bool> _zoomedByIndex = {};

  late List<Photo> _photos;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _photos = _photoList();
    _currentIndex = _photos.indexWhere((p) => p.id == widget.photo.id);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
    _focusNode = FocusNode();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    for (final c in _transformControllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Photo> _photoList() => widget.controller.visiblePhotos;

  void _onControllerChanged() {
    if (!mounted) return;
    final newList = _photoList();
    final currentId = _currentIndex < _photos.length
        ? _photos[_currentIndex].id
        : null;
    final newIndex = currentId == null
        ? -1
        : newList.indexWhere((p) => p.id == currentId);
    setState(() {
      _photos = newList;
      if (_photos.isEmpty) {
        Navigator.of(context).maybePop();
        return;
      }
      _currentIndex = newIndex >= 0
          ? newIndex
          : _currentIndex.clamp(0, _photos.length - 1);
    });
  }

  TransformationController _transformerFor(int index) {
    return _transformControllers.putIfAbsent(index, () {
      final c = TransformationController();
      c.addListener(() => _onTransformChanged(index, c));
      return c;
    });
  }

  void _onTransformChanged(int index, TransformationController c) {
    final isZoomed = c.value.getMaxScaleOnAxis() > 1.01;
    if ((_zoomedByIndex[index] ?? false) != isZoomed) {
      setState(() => _zoomedByIndex[index] = isZoomed);
    }
  }

  bool get _isCurrentZoomed => _zoomedByIndex[_currentIndex] ?? false;

  void _goTo(int index) {
    if (index < 0 || index >= _photos.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isCurrentZoomed) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: appBarBackLeading(context)),
        body: const SizedBox.shrink(),
      );
    }
    final currentPhoto = _photos[_currentIndex];
    final canSwipe = !_isCurrentZoomed;
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < _photos.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(currentPhoto.caption ?? ''),
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: canSwipe
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: _photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final photo = _photos[index];
                final uri = PhotoService.instance.photoPreviewUri(
                  widget.houseId,
                  photo.id,
                  size: 1024,
                );
                return InteractiveViewer(
                  transformationController: _transformerFor(index),
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: uri.toString(),
                      httpHeaders: widget.headers,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 64),
                    ),
                  ),
                );
              },
            ),
            if (_isDesktop && canSwipe && hasPrev)
              _NavButton(
                alignment: AlignmentDirectional.centerStart,
                icon: Icons.chevron_left,
                onPressed: () => _goTo(_currentIndex - 1),
              ),
            if (_isDesktop && canSwipe && hasNext)
              _NavButton(
                alignment: AlignmentDirectional.centerEnd,
                icon: Icons.chevron_right,
                onPressed: () => _goTo(_currentIndex + 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AlignmentGeometry alignment;
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({
    required this.alignment,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Material(
          color: Colors.black.withAlpha(110),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 32),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
