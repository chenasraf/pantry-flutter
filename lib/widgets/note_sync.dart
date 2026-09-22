import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// How a note says it mirrors a file, on the wall and in the note itself.
///
/// Both surfaces are drawn in the note's own ink over the note's own colour,
/// so the line is a dimmer shade of the text it sits under rather than a fixed
/// grey that would vanish on half the palette.

/// A note whose file the server could not find still holds its binding, and
/// the file coming back out of the trash resumes it. The two states earn
/// different icons because only one of them is worth acting on.
IconData _syncIcon(bool found) => found ? Icons.sync_alt : Icons.sync_problem;

/// The wall card's one-line badge: an icon and the file's path.
///
/// The path ellipsizes at its end rather than its start, because the filename
/// is the note's title — the folder is the half the card does not already say.
class NoteSyncLine extends StatelessWidget {
  final Note note;
  final Color textColor;

  const NoteSyncLine({super.key, required this.note, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = note.syncDisplayPath;
    final label = path == null
        ? m.notesWall.syncedFileMissing
        : m.notesWall.syncedToFile(path);
    final ink = textColor.withAlpha(180);

    return Row(
      children: [
        Icon(_syncIcon(path != null), size: 14, color: ink),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: detectTextDirection(label),
            style: theme.textTheme.bodySmall?.copyWith(color: ink),
          ),
        ),
      ],
    );
  }
}

/// The note's own header: the whole path, and when the two sides last agreed.
///
/// It sits above the body rather than under it, because knowing an edit here
/// lands in a file is worth knowing before typing rather than after.
class NoteSyncHeader extends StatelessWidget {
  final Note note;
  final Color textColor;

  const NoteSyncHeader({
    super.key,
    required this.note,
    required this.textColor,
  });

  /// Where the bound file opens in Files. Resolves for anyone with access and
  /// needs no path, so a file the server could not resolve is the only case
  /// with nowhere to go.
  Uri? get _fileUri {
    final fileId = note.syncFileId;
    final server = AuthService.instance.credentials?.serverUrl;
    if (fileId == null || server == null || note.syncPath == null) return null;
    return Uri.parse('$server/index.php/f/$fileId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = note.syncDisplayPath;
    final syncAt = note.syncAt;
    final label = path ?? m.notesWall.syncedFileMissing;
    final uri = _fileUri;

    final content = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _syncIcon(path != null),
            size: 16,
            color: textColor.withAlpha(180),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textDirection: detectTextDirection(label),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withAlpha(210),
                    decoration: uri != null ? TextDecoration.underline : null,
                  ),
                ),
                if (syncAt != null)
                  Text(
                    m.notesWall.syncedAt(relativeTime(syncAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(150),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (uri == null) return content;
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      child: content,
    );
  }
}
