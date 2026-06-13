import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

class WelcomeOnboardingPage extends StatelessWidget {
  final bool isNewUser;

  const WelcomeOnboardingPage({super.key, required this.isNewUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final title = isNewUser ? ob.welcomeNewTitle : ob.welcomeUpdateTitle;
    final body = isNewUser ? ob.welcomeNewBody : ob.welcomeUpdateBody;
    final icon = isNewUser ? Icons.waving_hand_outlined : Icons.auto_awesome;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
