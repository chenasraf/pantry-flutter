import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';

/// Result type for [ChecklistsDevLastSeenPickerDialog]. Carrying a wrapper
/// instead of a raw `String?` lets the dialog return "never seen" (null)
/// distinctly from dismissal.
class ChecklistsDevLastSeenChoice {
  /// `null` means simulate a brand-new user (no version seen yet).
  final String? value;

  const ChecklistsDevLastSeenChoice(this.value);
}

class ChecklistsDevLastSeenPickerDialog extends StatelessWidget {
  const ChecklistsDevLastSeenPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = m.onboarding.dev;
    final options = <ChecklistsDevLastSeenChoice>[
      const ChecklistsDevLastSeenChoice(null),
      for (final v in kDevOnboardingPickableVersions)
        ChecklistsDevLastSeenChoice(v),
    ];
    return SimpleDialog(
      title: Text(dev.pickLastSeenTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            dev.pickLastSeenBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final opt in options)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(opt),
            child: Text(opt.value ?? dev.neverSeen),
          ),
      ],
    );
  }
}
