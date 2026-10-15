import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import '../../../../../core/constants/app_colors.dart';
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
      title: const Text(AppStrings.qDeleteBook),
      content: Text(
        '"${book.title}" ${AppStrings.deleteBookMessage}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: onConfirm,
          child: const Text(AppStrings.delete),
        ),
      ],
    );
  }
}
