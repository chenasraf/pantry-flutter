import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/widgets/dashed_border.dart';

class AddImageButtons extends StatelessWidget {
  final VoidCallback onChooseImage;
  final VoidCallback? onTakePhoto;

  const AddImageButtons({
    super.key,
    required this.onChooseImage,
    this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    if (onTakePhoto == null) {
      return _AddImageTile(
        icon: Icons.add_photo_alternate_outlined,
        label: f.addImage,
        onTap: onChooseImage,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _AddImageTile(
            icon: Icons.photo_camera_outlined,
            label: f.takePhoto,
            onTap: onTakePhoto!,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AddImageTile(
            icon: Icons.add_photo_alternate_outlined,
            label: f.chooseImage,
            onTap: onChooseImage,
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddImageTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DashedBorder(
        color: cs.outlineVariant,
        radius: 14,
        strokeWidth: 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(f.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.add_photo_alternate_outlined),
            title: Text(f.chooseImage),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
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
          borderRadius: BorderRadius.circular(14),
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
