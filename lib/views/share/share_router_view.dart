import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/services/deep_link_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/pending_note_share_service.dart';
import 'package:pantry/services/pending_photo_share_service.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// Entry screen for an incoming OS share intent. Classifies the payload,
/// optionally asks the user to pick a house, and then routes:
///   * photo flow → folder picker → enqueue uploads → switch to photo tab
///   * text/URL flow → push the notes-form view prefilled with the content
///
/// On completion this view pops itself. On cancel/error it also pops.
class ShareRouterView extends StatefulWidget {
  final List<SharedMediaFile> files;

  const ShareRouterView({super.key, required this.files});

  @override
  State<ShareRouterView> createState() => _ShareRouterViewState();
}

class _ShareRouterViewState extends State<ShareRouterView> {
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final houses = await HouseService.instance.getHouses();
      if (!mounted) return;
      if (houses.isEmpty) {
        setState(() {
          _busy = false;
          _error = m.share.noHouses;
        });
        return;
      }

      final house = houses.length == 1
          ? houses.first
          : await _pickHouse(houses);
      if (!mounted) return;
      if (house == null) {
        Navigator.of(context).pop();
        return;
      }

      final hasImages = widget.files.any(
        (f) => f.type == SharedMediaType.image,
      );
      if (hasImages) {
        await _runPhotoFlow(house);
      } else {
        await _runNoteFlow(house);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = m.share.failedToOpenShare;
      });
    }
  }

  Future<House?> _pickHouse(List<House> houses) async {
    return showDialog<House>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.share.chooseHouse),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        children: houses
            .map(
              (h) => ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(h.name),
                onTap: () => Navigator.pop(ctx, h),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _runPhotoFlow(House house) async {
    // Fetch folders for the selected house (used in the picker).
    List<PhotoFolder> folders;
    try {
      folders = await PhotoService.instance.getFolders(house.id);
    } catch (_) {
      folders = [];
    }
    if (!mounted) return;

    final dest = await showModalBottomSheet<_PhotoDestination>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _PhotoDestinationPicker(folders: folders, houseId: house.id),
    );
    if (!mounted) return;
    if (dest == null) {
      Navigator.of(context).pop();
      return;
    }

    int? folderId = dest.folderId;
    if (dest.newFolderName != null) {
      try {
        final folder = await PhotoService.instance.createFolder(
          house.id,
          name: dest.newFolderName!,
        );
        folderId = folder.id;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.share.failedToCreateFolder)));
        }
        return;
      }
    }

    final paths = widget.files
        .where((f) => f.type == SharedMediaType.image)
        .map((f) => f.path)
        .toList();

    await PrefsService.instance.setLastHouseId(house.id);
    if (!mounted) return;

    Navigator.of(context).pop();
    DeepLinkService.instance.push(DeepLink(tabIndex: 1, houseId: house.id));
    PendingPhotoShareService.instance.enqueue(
      PendingPhotoShare(houseId: house.id, folderId: folderId, paths: paths),
    );
  }

  Future<void> _runNoteFlow(House house) async {
    final text = widget.files
        .where(
          (f) =>
              f.type == SharedMediaType.text || f.type == SharedMediaType.url,
        )
        .map((f) => f.path)
        .where((s) => s.isNotEmpty)
        .join('\n\n');

    await PrefsService.instance.setLastHouseId(house.id);
    if (!mounted) return;

    // Pop the share router BEFORE notifying listeners. If the notes wall
    // is already mounted, its listener pushes the form synchronously, and
    // we don't want our own pop to remove that form by accident.
    Navigator.of(context).pop();
    DeepLinkService.instance.push(DeepLink(tabIndex: 2, houseId: house.id));
    PendingNoteShareService.instance.push(
      PendingNoteShare(houseId: house.id, content: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.share.title),
      ),
      body: Center(
        child: _busy
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(m.common.cancel),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PhotoDestination {
  /// null = root, or a real folder id.
  final int? folderId;

  /// non-null when the user picked "new folder" with this name.
  final String? newFolderName;

  const _PhotoDestination.root() : folderId = null, newFolderName = null;
  const _PhotoDestination.folder(this.folderId) : newFolderName = null;
  const _PhotoDestination.newFolder(this.newFolderName) : folderId = null;
}

class _PhotoDestinationPicker extends StatelessWidget {
  final List<PhotoFolder> folders;
  final int houseId;

  const _PhotoDestinationPicker({required this.folders, required this.houseId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Text(
                m.share.choosePhotoDestination,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(m.share.photoBoardRoot),
              onTap: () =>
                  Navigator.pop(context, const _PhotoDestination.root()),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final folder in folders)
                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      onTap: () => Navigator.pop(
                        context,
                        _PhotoDestination.folder(folder.id),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(m.share.newFolder),
              onTap: () => _promptNewFolder(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptNewFolder(BuildContext context) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.share.newFolder),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.share.newFolderName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) Navigator.pop(ctx, name);
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      Navigator.pop(context, _PhotoDestination.newFolder(result));
    }
  }
}
