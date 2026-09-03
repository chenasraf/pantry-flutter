import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry/widgets/dashed_border.dart';
import 'package:pantry/widgets/markdown_description.dart';
import 'package:pantry/widgets/member_avatar.dart';
import 'checklists_controller.dart';

class OverflowAction {
  final String value;
  final IconData icon;
  final String label;

  const OverflowAction({
    required this.value,
    required this.icon,
    required this.label,
  });
}

class DescriptionCard extends StatefulWidget {
  final ListItem item;
  final ChecklistsController controller;

  /// Whether the user may flip checkboxes. When false the checkboxes still
  /// render but are inert (read-only shared lists).
  final bool canToggle;

  const DescriptionCard({
    super.key,
    required this.item,
    required this.controller,
    required this.canToggle,
  });

  @override
  State<DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<DescriptionCard> {
  late String? _description = widget.item.description;

  @override
  void didUpdateWidget(DescriptionCard old) {
    super.didUpdateWidget(old);
    // Follow external edits (e.g. the edit sheet) unless we're mid-toggle.
    if (widget.item.description != old.item.description) {
      _description = widget.item.description;
    }
  }

  void _onDescriptionChanged(String updated) {
    setState(() => _description = updated);
    widget.controller.updateItem(widget.item, description: updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final v = m.checklists.viewItem;
    final description = _description;
    final hasDesc = description != null && description.trim().isNotEmpty;

    final label = Text(
      v.descriptionLabel.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: cs.onSurfaceVariant,
      ),
    );

    if (!hasDesc) {
      return DashedBorder(
        radius: 15,
        strokeWidth: 1,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        color: cs.outlineVariant,
        background: cs.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 5),
            Text(
              v.noDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 8),
          MarkdownDescription(
            description: description,
            onChanged: widget.canToggle ? _onDescriptionChanged : null,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetaRow extends StatelessWidget {
  final ListItem item;
  final ChecklistsController controller;

  const MetaRow({super.key, required this.item, required this.controller});

  String _actorName(String uid) => controller.members[uid]?.displayName ?? uid;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = m.checklists.viewItem;
    final currentUser = AuthService.instance.credentials?.loginName;

    final addedBy = item.addedBy;
    final hasAuthor = addedBy != null && addedBy.isNotEmpty;
    final addedByYou = hasAuthor && addedBy == currentUser;
    final addedTime = relativeTime(item.createdAt);
    // When the author is unknown (older items without an `addedBy`), drop
    // the "by … " segment, hide the avatar, and lead with "Added {time}".
    final addedText = !hasAuthor
        ? v.addedMeta(addedTime)
        : addedByYou
        ? v.addedByYouMeta(addedTime)
        : v.addedByMeta(_actorName(addedBy), addedTime);

    final doneAt = item.doneAt;
    final showDone = item.done && doneAt != null;
    final doneBy = item.doneBy;
    final hasDoneAuthor = doneBy != null && doneBy.isNotEmpty;
    final doneByYou = hasDoneAuthor && doneBy == currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaLine(
          leading: hasAuthor
              ? MemberAvatar(
                  userId: addedBy,
                  displayName: _actorName(addedBy),
                  size: 28,
                )
              : null,
          text: addedText,
          color: cs.onSurfaceVariant,
        ),
        if (showDone)
          _MetaLine(
            leading: Icon(
              Icons.check_circle_outline,
              size: 20,
              color: cs.primary,
            ),
            text: !hasDoneAuthor
                ? v.doneMeta(relativeTime(doneAt))
                : doneByYou
                ? v.doneByYouMeta(relativeTime(doneAt))
                : v.doneByMeta(_actorName(doneBy), relativeTime(doneAt)),
            color: cs.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  final Widget? leading;
  final String text;
  final Color color;

  const _MetaLine({
    required this.leading,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(width: 28, child: Center(child: leading)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DockedEditBar extends StatelessWidget {
  final VoidCallback onTap;

  const DockedEditBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Text(
                  m.checklists.editItem,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
