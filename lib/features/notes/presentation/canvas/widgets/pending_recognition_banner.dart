import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';

class PendingRecognitionBanner extends StatelessWidget {
  final String text;
  final TextDirection textDirection;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;
  final VoidCallback onEdit;

  const PendingRecognitionBanner({
    super.key,
    required this.text,
    required this.textDirection,
    required this.onConfirm,
    required this.onDiscard,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: AppColors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
                textDirection: textDirection,
              ),
            ),
            const SizedBox(width: 6),
            _MiniIcon(
              icon: Icons.close,
              color: AppColors.grey,
              tooltip: AppStrings.keepDrawing,
              onTap: onDiscard,
            ),
            _MiniIcon(
              icon: Icons.edit_outlined,
              color: AppColors.blueGrey,
              tooltip: AppStrings.fixText,
              onTap: onEdit,
            ),
            _MiniIcon(
              icon: Icons.check_circle,
              color: AppColors.green,
              tooltip: AppStrings.insertAsText,
              onTap: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}