import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

Future<String?> showHabitNoteDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (dialogContext) => const _HabitNoteDialog(),
  );
}

class _HabitNoteDialog extends StatefulWidget {
  const _HabitNoteDialog();

  @override
  State<_HabitNoteDialog> createState() => _HabitNoteDialogState();
}

class _HabitNoteDialogState extends State<_HabitNoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.palette.secondaryBackground,
      title: const Text('Add a note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'How did it go? (optional)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
