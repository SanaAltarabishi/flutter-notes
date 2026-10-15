import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool compact;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.compact = false,
  });

  Future<void> _pickColor(BuildContext context) async {
    final pickedColor = await showColorPickerDialog(
      context,
      selectedColor,
      title: const Text(AppStrings.chooseCoverColor),
      showColorCode: true,
      showColorName: true,
      enableOpacity: false,
      pickersEnabled: const {
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.wheel: true,
        ColorPickerType.custom: false,
      },
    );

    if (pickedColor != selectedColor) {
      onColorSelected(pickedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _pickColor(context),
        icon: const Icon(Icons.add),
        tooltip: AppStrings.chooseColor,
        style: IconButton.styleFrom(
          fixedSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: selectedColor,
          foregroundColor:
              ThemeData.estimateBrightnessForColor(selectedColor) ==
                      Brightness.dark
                  ? AppColors.white
                  : AppColors.black,
        ),
      );
    }

    return InkWell(
      onTap: () => _pickColor(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.coverColor,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppStrings.tapToChooseColor,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.palette_outlined),
          ],
        ),
      ),
    );
  }
}
