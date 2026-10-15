import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import '../../../../../core/constants/app_colors.dart';

//✅
class ClearCanvasDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ClearCanvasDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        AppStrings.clearCanvasDialogTitle,
      ),
      content: const Text(
        AppStrings.clearCanvasDialogMessage,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            AppStrings.clearCanvasDialogCancel,
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text(
            AppStrings.clearCanvasDialogClear,
          ),
        ),
      ],
    );
  }
}

//____________
Future<void> showClearCanvasDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (_) => ClearCanvasDialog(
      onConfirm: onConfirm,
    ),
  );
}
