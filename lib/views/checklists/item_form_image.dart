import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/file_attach.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/nextcloud_files_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/widgets/avif_image.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/widgets/dashed_border.dart';

/// Where an item's image comes from.
enum ImagePickSource { camera, device, nextcloud }

/// The label for picking from this device's own files or photos: a computer
/// has no gallery, and on a phone "computer" would be wrong.
String get _fromDeviceLabel => PlatformInfo.isDesktop
    ? m.checklists.itemForm.fromComputer
    : m.checklists.itemForm.fromDevice;

/// A preview of an image picked from the account's Nextcloud files, before it
/// is attached.
ImageProvider nextcloudPickImage(NextcloudImagePick pick, {int size = 256}) =>
    AvifAwareNetworkImage(
      NextcloudFilesService.instance
          .imagePreviewUri(pick.fileId, size: size)
          .toString(),
      headers: AuthService.instance.credentials?.basicAuthHeaders ?? {},
    );

/// Asks where a replacement image comes from, or goes straight to the device's
/// picker when that is the only source. Null when dismissed.
Future<ImagePickSource?> chooseImageSource(
  BuildContext context, {
  required bool cameraSupported,
}) async {
  final nextcloud = ServerFeature.imagesFromFiles;
  if (!cameraSupported && !nextcloud) return ImagePickSource.device;
  return showModalBottomSheet<ImagePickSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) =>
        ImageSourceSheet(showCamera: cameraSupported, showNextcloud: nextcloud),
  );
}

class AddImageButtons extends StatelessWidget {
  final VoidCallback onChooseImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onFromNextcloud;

  const AddImageButtons({
    super.key,
    required this.onChooseImage,
    this.onTakePhoto,
    this.onFromNextcloud,
  });

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    final tiles = [
      if (onTakePhoto != null)
        (
          icon: Icons.photo_camera_outlined,
          label: f.takePhoto,
          onTap: onTakePhoto!,
        ),
      (
        icon: Icons.add_photo_alternate_outlined,
        // A lone tile needs no source to set it apart from the others.
        label: onTakePhoto == null && onFromNextcloud == null
            ? f.addImage
            : _fromDeviceLabel,
        onTap: onChooseImage,
      ),
      if (onFromNextcloud != null)
        (
          icon: Icons.cloud_outlined,
          label: f.fromNextcloud,
          onTap: onFromNextcloud!,
        ),
    ];
    // Three tiles side by side leave a phone too little width for an icon
    // beside each label, so they stack it above.
    final stacked = tiles.length > 2;
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _AddImageTile(
              icon: tiles[i].icon,
              label: tiles[i].label,
              onTap: tiles[i].onTap,
              stacked: stacked,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool stacked;

  const _AddImageTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Text(
      label,
      maxLines: stacked ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: stacked ? 13.5 : 14.5,
        fontWeight: FontWeight.w700,
        color: cs.primary,
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SurfaceRadius.card),
      child: DashedBorder(
        color: cs.outlineVariant,
        radius: SurfaceRadius.card,
        strokeWidth: 1.5,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: stacked ? 12 : 18,
            horizontal: stacked ? 8 : 12,
          ),
          child: stacked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: cs.primary, size: 22),
                    const SizedBox(height: 6),
                    text,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: cs.primary, size: 20),
                    const SizedBox(width: 9),
                    Flexible(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}

class ImageSourceSheet extends StatelessWidget {
  final bool showCamera;
  final bool showNextcloud;

  const ImageSourceSheet({
    super.key,
    this.showCamera = true,
    this.showNextcloud = false,
  });

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(f.takePhoto),
              onTap: () => Navigator.pop(context, ImagePickSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.add_photo_alternate_outlined),
            title: Text(_fromDeviceLabel),
            onTap: () => Navigator.pop(context, ImagePickSource.device),
          ),
          if (showNextcloud)
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(f.fromNextcloud),
              onTap: () => Navigator.pop(context, ImagePickSource.nextcloud),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ImagePreviewTile extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const ImagePreviewTile({
    super.key,
    required this.image,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SurfaceRadius.card),
          child: Image(
            image: image,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageActionButton(
                icon: Icons.swap_horiz,
                tooltip: f.replaceImage,
                onPressed: onReplace,
              ),
              const SizedBox(width: 4),
              _ImageActionButton(
                icon: Icons.close,
                tooltip: f.removeImage,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ImageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
