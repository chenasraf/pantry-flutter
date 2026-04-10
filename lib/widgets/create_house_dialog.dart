import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/views/home/home_controller.dart';

/// Shows a dialog for creating a new house. Returns the created [House]
/// on success, or null if cancelled.
Future<House?> showCreateHouseDialog(
  BuildContext context,
  HomeController controller,
) {
  return showDialog<House>(
    context: context,
    builder: (_) => CreateHouseDialog(controller: controller),
  );
}

class CreateHouseDialog extends StatefulWidget {
  final HomeController controller;

  const CreateHouseDialog({super.key, required this.controller});

  @override
  State<CreateHouseDialog> createState() => _CreateHouseDialogState();
}

class _CreateHouseDialogState extends State<CreateHouseDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final house = await widget.controller.addHouse(
        name: name,
        description: _descriptionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(house);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.home.createHouseFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(m.home.createHouse),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: m.home.houseName,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: m.home.houseDescription,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(m.common.save),
        ),
      ],
    );
  }
}
