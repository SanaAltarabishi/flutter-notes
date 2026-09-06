import 'package:flutter/material.dart';

import '../../../domain/entities/book.dart';

class DeleteBookDialog extends StatelessWidget {
  final Book book;
  final VoidCallback onConfirm;

  const DeleteBookDialog({
    super.key,
    required this.book,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete book?'),

      content: Text(
        '"${book.title}" and all its pages '
        'will be deleted.',
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: onConfirm,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}