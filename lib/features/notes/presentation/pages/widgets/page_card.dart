import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import '../../../domain/entities/page.dart';

class PageCard extends StatelessWidget {
  final NotePage page;
  final VoidCallback onTap;
  final VoidCallback onEditName;
  final VoidCallback onDelete;

  const PageCard({
    super.key,
    required this.page,
    required this.onTap,
    required this.onEditName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.bookDateText.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Paper preview
              _PagePreview(
                accentColor: AppColors.primary,
              ),
              const SizedBox(width: 16),

              // Page name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      page.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // style: theme.textTheme.titleMedium?.copyWith(
                      //   fontWeight: FontWeight.w600,
                      //   letterSpacing: -0.3,
                      // ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to open',
                      // style: theme.textTheme.bodySmall?.copyWith(
                      //   color: colors.onSurfaceVariant,
                      // ),
                    ),
                  ],
                ),
              ),

              // Edit and delete menu
              PopupMenuButton<String>(
                tooltip: 'Page options',
                icon: Icon(
                  Icons.more_horiz,
                  color: AppColors.seedColor.withValues(alpha: 0.7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEditName();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit name'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
//  final bool isDark;
  final Color accentColor;

  const _PagePreview({
    //  required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const paperColor = Color(0xFFFFFEFA);
    const lineColor = Color(0xFFD9DEE8);

    return Container(
      width: 66,
      height: 82,
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE4E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Faint writing lines
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  18,
                  8,
                  8,
                ),
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 1,
                          width: index == 3 ? 25 : 39,
                          color: lineColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Colored spine
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: accentColor.withValues(alpha: 0.8),
              ),
            ),

            // Folded top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(15, 15),
                painter: _FoldPainter(
                  color: const Color(0xFFE8E8E5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//__________________________________
class _FoldPainter extends CustomPainter {
  final Color color;

  _FoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FoldPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
