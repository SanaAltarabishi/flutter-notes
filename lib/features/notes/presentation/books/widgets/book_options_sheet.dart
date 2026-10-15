import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';

class BookOptionsSheet extends StatelessWidget {
 // final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BookOptionsSheet({
    super.key,
 //   required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.edit_outlined,
            ),
            title: const Text(AppStrings.edit),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
            title: Text(
              AppStrings.delete,
              style: TextStyle(
                color: AppColors.error,
              ),
            ),
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
