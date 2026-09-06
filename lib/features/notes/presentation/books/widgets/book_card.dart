import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class BookCard extends StatelessWidget {
  static const BorderRadius _borderRadius = BorderRadius.only(
    topLeft: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    topRight: Radius.circular(8),
    bottomRight: Radius.circular(8),
  );

  static const BorderRadius _pageBorderRadius = BorderRadius.only(
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(6),
    topLeft: Radius.circular(2),
    bottomLeft: Radius.circular(2),
  );
//_________________________________________________________

  final String title;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final Color coverColor;

  const BookCard({
    super.key,
    required this.title,
    required this.createdAt,
    this.onTap,
    this.coverColor = AppColors.seedColor,
  });
//_________________________________________________________

  String get _formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
//_________________________________________________________

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.bookShadow,
              blurRadius: 14,
              offset: Offset(4, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildPageBlock(),
            _buildCover(),
          ],
        ),
      ),
    );
  }

//_________________________________________________________
  // Page Block
  Widget _buildPageBlock() {
    return Positioned(
      left: 6,
      top: 6,
      right: -3,
      bottom: -3,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bookPage,
          borderRadius: _pageBorderRadius,
        ),
        child: CustomPaint(
          painter: _PageEdgesPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

//_________________________________________________________
  // Cover
  Widget _buildCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              coverColor,
              AppColors.white,
              0.18,
            )!,
            coverColor,
            Color.lerp(
              coverColor,
              Colors.black,
              0.35,
            )!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bookCoverShadow,
            blurRadius: 6,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Stack(
          children: [
            _buildGloss(),
            _buildSpine(),
            _buildHinge(),
            _buildTitle(),
            _buildDivider(),
            _buildDate(),
          ],
        ),
      ),
    );
  }

//_________________________________________________________
  // Gloss

  Widget _buildGloss() {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bookGloss,
              Colors.transparent,
              Colors.transparent,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
      ),
    );
  }

//_________________________________________________________
  // Spine

  Widget _buildSpine() {
    return const Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.bookSpineDark,
               Color(0x26000000),
              AppColors.bookSpineHighlight,
            ],
            stops:  [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }

//_________________________________________________________
  // Hinge
  Widget _buildHinge() {
    return Positioned(
      left: 18,
      top: 0,
      bottom: 0,
      width: 2,
      child: Container(
        color: AppColors.bookHinge,
      ),
    );
  }
//_________________________________________________________

  // Title
  Widget _buildTitle() {
    return Positioned(
      left: 32,
      right: 18,
      top: 40,
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: AppColors.bookTitleShadow,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

//_________________________________________________________
  // Divider

  Widget _buildDivider() {
    return Positioned(
      left: 40,
      right: 35,
      bottom: 50,
      child: Container(
        height: 1,
        color: AppColors.bookDivider,
      ),
    );
  }

//_________________________________________________________
  // Date

  Widget _buildDate() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 25,
      child: Text(
        _formattedDate,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.bookDateText,
          fontSize: 12,
        ),
      ),
    );
  }
}
//_________________________________________________________

// Draws thin horizontal lines to simulate individual page edges.
class _PageEdgesPainter extends CustomPainter {
  static const double _spacing = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bookPageEdge
      ..strokeWidth = 1;

    for (double y = 4; y < size.height - 4; y += _spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
