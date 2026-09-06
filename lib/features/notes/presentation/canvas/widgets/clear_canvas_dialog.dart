import 'package:flutter/material.dart';

Future<void> showClearCanvasDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear canvas?'),
      content: const Text('All strokes will be deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}