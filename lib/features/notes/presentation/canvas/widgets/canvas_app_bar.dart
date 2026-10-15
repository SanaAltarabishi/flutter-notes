import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';

//✅
class CanvasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSave;

  const CanvasAppBar({
    super.key,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(AppStrings.appName),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          tooltip: AppStrings.saveDrawing,
        ),
      ],
    );
  }
}
