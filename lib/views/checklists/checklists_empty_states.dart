import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/theme/app_theme.dart';

class ChecklistsNoMatchesEmptyState extends StatelessWidget {
  const ChecklistsNoMatchesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          m.checklists.noSearchResults,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class ChecklistsNoItemsEmptyState extends StatelessWidget {
  const ChecklistsNoItemsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final success = AppSurfaces.of(context).success;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          success.withValues(alpha: 0.18),
                          success.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.check_box_outlined,
                      color: success,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    m.checklists.noItemsTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    m.checklists.noItemsBody,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Icon(
            Icons.keyboard_double_arrow_down,
            color: cs.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class ChecklistsNoListsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const ChecklistsNoListsEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.primary.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: cs.primary,
                size: 46,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              m.checklists.noListsTitle,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 9),
            Text(
              m.checklists.noListsBody,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: surfaces.primaryButton(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: surfaces.onAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      m.checklists.createFirstList,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: surfaces.onAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
