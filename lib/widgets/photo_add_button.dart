import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

class PhotoAddButton extends StatefulWidget {
  final PhotoBoardController controller;

  const PhotoAddButton({super.key, required this.controller});

  @override
  State<PhotoAddButton> createState() => _PhotoAddButtonState();
}

class _PhotoAddButtonState extends State<PhotoAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _open = false;
  bool _cameraSupported = !Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    if (_cameraSupported) {
      isiOSAppOnMac().then((onMac) {
        if (!mounted || !onMac) return;
        setState(() => _cameraSupported = false);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _animController.reverse();
  }

  Future<void> _pickPhotos() async {
    _close();
    final useFilePicker = Platform.isMacOS || await isiOSAppOnMac();
    if (useFilePicker) {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result == null) return;
      final files = [
        for (final f in result.files)
          if (f.path != null) XFile(f.path!, name: f.name),
      ];
      if (files.isNotEmpty) {
        widget.controller.uploadPhotos(files);
      }
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      widget.controller.uploadPhotos(files);
    }
  }

  Future<void> _takePhoto() async {
    _close();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      widget.controller.uploadPhotos([file]);
    }
  }

  Future<void> _createFolderDialog() async {
    _close();
    if (!mounted) return;
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(m.photoBoard.newFolder),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.photoBoard.folderName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final v = value.trim();
            if (v.isNotEmpty) Navigator.pop(dialogCtx, v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = textController.text.trim();
              if (v.isNotEmpty) Navigator.pop(dialogCtx, v);
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      widget.controller.createFolder(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_FabAction>[
      _FabAction(
        icon: Icons.add_photo_alternate,
        label: m.photoBoard.addMenu.upload,
        onTap: _pickPhotos,
      ),
      if (_cameraSupported)
        _FabAction(
          icon: Icons.camera_alt,
          label: m.photoBoard.addMenu.camera,
          onTap: _takePhoto,
        ),
      _FabAction(
        icon: Icons.create_new_folder,
        label: m.photoBoard.addMenu.newFolder,
        onTap: _createFolderDialog,
      ),
    ];

    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _close();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_open,
              child: AnimatedOpacity(
                opacity: _open ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const ColoredBox(color: Color(0x66000000)),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < actions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnimatedAction(
                      action: actions[i],
                      controller: _animController,
                      index: actions.length - 1 - i,
                      total: actions.length,
                    ),
                  ),
                _buildMainFab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFab() {
    return FloatingActionButton(
      heroTag: 'photo_add_menu_main',
      onPressed: _toggle,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (ctx, _) {
          return Transform.rotate(
            angle: _animController.value * (math.pi * 3 / 4),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _AnimatedAction extends StatelessWidget {
  final _FabAction action;
  final AnimationController controller;
  final int index;
  final int total;

  const _AnimatedAction({
    required this.action,
    required this.controller,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / total) * 0.4;
    final end = math.min(1.0, start + 0.7);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, child) {
        final v = anim.value.clamp(0.0, 1.0);
        if (v == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: child,
          ),
        );
      },
      child: _ActionRow(action: action),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _FabAction action;
  const _ActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: scheme.surfaceContainerHighest,
          elevation: 2,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                action.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: scheme.secondaryContainer,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: action.onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(action.icon, color: scheme.onSecondaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
