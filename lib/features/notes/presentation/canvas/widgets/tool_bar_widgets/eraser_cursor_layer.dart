import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EraserCursorLayer extends StatelessWidget {
  final ValueListenable<Offset?> position;
  final double radius;

  const EraserCursorLayer({
    super.key,
    required this.position,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: this layer never receives touches, they go to the
    // canvas below. (A CustomPaint with a painter would absorb them.)
    return IgnorePointer(
      // RepaintBoundary: the ring repaints alone, without the canvas.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EraserCursorPainter(position: position, radius: radius),
        ),
      ),
    );
  }
}

class _EraserCursorPainter extends CustomPainter {
  final ValueListenable<Offset?> position;
  final double radius;

  _EraserCursorPainter({required this.position, required this.radius})
      : super(repaint: position);
  final Paint _fill = Paint()..color = const Color(0x1F000000);
  final Paint _halo = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xE6FFFFFF);

  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFF424242);

  @override
  void paint(Canvas canvas, Size size) {
    final center = position.value;
    if (center == null) return;
    canvas.drawCircle(center, radius, _fill);
    canvas.drawCircle(center, radius, _halo);
    canvas.drawCircle(center, radius, _ring);
  }

  @override
  bool shouldRepaint(_EraserCursorPainter old) =>
      old.radius != radius || old.position != position;
}