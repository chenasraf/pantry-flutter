import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/utils/apple_host_info.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

/// Offers the board's ways of adding a photo to the home nav's trailing
/// button, which fans them out above itself.
///
/// Draws nothing of its own — it lives in the board's tree only to hold the
/// camera probe and to re-offer the actions as permissions change.
class PhotoAddActions extends StatefulWidget {
  final PhotoBoardController controller;
  final ValueNotifier<NavPrimaryAction?>? holder;

  /// False in the trash view, where there is nothing to add to.
  final bool enabled;

  const PhotoAddActions({
    super.key,
    required this.controller,
    required this.holder,
    this.enabled = true,
  });

  @override
  State<PhotoAddActions> createState() => _PhotoAddActionsState();
}

class _PhotoAddActionsState extends State<PhotoAddActions> {
  bool _cameraSupported = !PlatformInfo.isDesktop;

  @override
  void initState() {
    super.initState();
    // Drop whatever the previous board left in the nav slot. An offer from this
    // one looks identical and would be discarded as unchanged, leaving the
    // button wired to a board that is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.holder?.value = null;
    });
    if (_cameraSupported) {
      isiOSAppOnMac().then((onMac) {
        if (!mounted || !onMac) return;
        setState(() => _cameraSupported = false);
      });
    }
  }

  Future<void> _pickPhotos() async {
    final useFilePicker = PlatformInfo.isMacOS || await isiOSAppOnMac();
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
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      widget.controller.uploadPhotos([file]);
    }
  }

  Future<void> _createFolderDialog() async {
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
    final holder = widget.holder;
    if (holder == null) return const SizedBox.shrink();

    final perms = widget.controller.permissions;
    final actions = <NavMenuAction>[
      if (widget.enabled && perms.canUploadPhotos)
        (
          icon: Icons.add_photo_alternate,
          label: m.photoBoard.addMenu.upload,
          onTap: _pickPhotos,
        ),
      if (widget.enabled && perms.canUploadPhotos && _cameraSupported)
        (
          icon: Icons.camera_alt,
          label: m.photoBoard.addMenu.camera,
          onTap: _takePhoto,
        ),
      if (widget.enabled && perms.canMovePhotos)
        (
          icon: Icons.create_new_folder,
          label: m.photoBoard.addMenu.newFolder,
          onTap: _createFolderDialog,
        ),
    ];

    // Nothing the user may do here — leave the button off the bar entirely.
    final offer = actions.isEmpty
        ? null
        : NavPrimaryAction(icon: Icons.add, label: m.common.add, menu: actions);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      holder.value = offer;
    });

    return const SizedBox.shrink();
  }
}
