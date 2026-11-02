import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';

//✅
class CanvasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSave;
  final String pageTitle;

  const CanvasAppBar({
    super.key,
    required this.onSave,
    required this.pageTitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(pageTitle),
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
