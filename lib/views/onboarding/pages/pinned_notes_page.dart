import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/text_direction.dart';

/// Tells users that notes can be pinned from the overflow menu to keep them
/// at the top of the Notes Wall. Renders a stylised pinned-note card that
/// matches the real `NoteTile` look (pin icon + title + content) so the
/// reader recognises the affordance the moment they next open the wall.
class PinnedNotesOnboardingPage extends StatelessWidget {
  const PinnedNotesOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.pinnedNotesTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.pinnedNotesBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(width: 200, height: 180, child: _PinnedNoteMock()),
          ),
        ],
      ),
    );
  }
}

/// Stylised pinned note tile — matches the real `NoteTile` foreground layout
/// (pin glyph + title + content + overflow menu icon) so the user recognises
/// what a pinned note looks like on their Notes Wall.
class _PinnedNoteMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final bgColor = cs.tertiaryContainer;
    final textColor = cs.onTertiaryContainer;
    final titleDir = detectTextDirection(ob.mockPinnedNoteTitle);
    final contentDir = detectTextDirection(ob.mockPinnedNoteContent);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, size: 14, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Directionality(
                  textDirection: titleDir,
                  child: Text(
                    ob.mockPinnedNoteTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Icon(Icons.more_vert, size: 18, color: textColor),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Directionality(
              textDirection: contentDir,
              child: Text(
                ob.mockPinnedNoteContent,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withAlpha(200),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
