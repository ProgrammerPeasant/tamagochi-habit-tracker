import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

Future<String?> showHabitNoteDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: dialogContext.palette.secondaryBackground,
        title: const Text('Add a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'How did it go? (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}
