import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/views/home/home_controller.dart';
import 'package:pantry/widgets/create_house_dialog.dart';

class NoHousesView extends StatelessWidget {
  final HomeController controller;

  const NoHousesView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              m.home.noHouses,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              m.home.noHousesBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showCreateHouseDialog(context, controller),
              icon: const Icon(Icons.add),
              label: Text(m.home.createHouse),
            ),
          ],
        ),
      ),
    );
  }
}
