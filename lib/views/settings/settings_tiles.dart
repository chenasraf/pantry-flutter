import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A settings screen's scrolling body, carrying the muted subtitle styling
/// every settings row shares.
class SettingsList extends StatelessWidget {
  final List<Widget> children;

  const SettingsList({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTileTheme(
      data: theme.listTileTheme.copyWith(
        subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      child: ListView(children: children),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Explanatory text under a section header.
class SettingsSectionBody extends StatelessWidget {
  final String text;

  const SettingsSectionBody(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A settings row that opens another screen.
class SettingsPageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsPageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final forward = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(forward),
      onTap: onTap,
    );
  }
}

/// A settings row with a value dropdown. The dropdown normally sits at the end
/// of the row, but drops below the title when the (translated) title would be
/// squeezed narrower than its longest word — which otherwise forces an ugly
/// character-by-character wrap in longer locales.
class DropdownSettingTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const DropdownSettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  static double _measureWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final titleStyle =
        theme.listTileTheme.titleTextStyle ?? theme.textTheme.bodyLarge!;
    final dropdownStyle = theme.textTheme.titleMedium!;

    final dropdown = DropdownButton<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      items: [
        for (final option in options)
          DropdownMenuItem<T>(value: option, child: Text(labelOf(option))),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Footprint of the collapsed dropdown: widest label plus its arrow,
        // capped at half the row so a long value can't crowd out the title.
        var widestLabel = 0.0;
        for (final option in options) {
          final w = _measureWidth(
            labelOf(option),
            dropdownStyle,
            textScaler,
            textDirection,
          );
          if (w > widestLabel) widestLabel = w;
        }
        const arrowWidth = 24.0;
        final dropdownWidth = math.min(
          widestLabel + arrowWidth + 8,
          maxWidth * 0.5,
        );

        // ListTile overhead beside the title: content padding (16 each side),
        // the leading icon slot (40) and the gaps around the title (16 each).
        const overhead = 16.0 + 40.0 + 16.0 + 16.0 + 16.0;
        final titleColWidth = maxWidth - overhead - dropdownWidth;

        var longestWord = 0.0;
        for (final word in title.split(RegExp(r'\s+'))) {
          final w = _measureWidth(word, titleStyle, textScaler, textDirection);
          if (w > longestWord) longestWord = w;
        }

        if (longestWord <= titleColWidth) {
          return ListTile(
            enabled: enabled,
            leading: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle!),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dropdownWidth),
              child: dropdown,
            ),
          );
        }

        return ListTile(
          enabled: enabled,
          titleAlignment: ListTileTitleAlignment.top,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) Text(subtitle!),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: dropdown,
              ),
            ],
          ),
        );
      },
    );
  }
}
