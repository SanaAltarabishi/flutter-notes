import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TrailPoint {
  final Offset position;
  final DateTime time;

  const TrailPoint(
    this.position,
    this.time,
  );
}

class MagicTrailLayer extends StatefulWidget {
  final Color color;
  static const Duration trailDuration = Duration(milliseconds: 450);

  const MagicTrailLayer({
    super.key,
    required this.color,
  });

  @override
  State<MagicTrailLayer> createState() => _MagicTrailLayerState();
}

class _MagicTrailLayerState extends State<MagicTrailLayer>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<List<TrailPoint>> _points =
      ValueNotifier<List<TrailPoint>>([]);

  late final Timer _fadeTimer;
  late final AnimationController _animationController;

  // ============================================================
  // HOW LONG THE TAIL REMAINS VISIBLE
  // ============================================================

  static const Duration trailDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();

    // ============================================================
    // STAR ROTATION
    // ============================================================

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // ============================================================
    // REMOVE OLD POINTS
    // ============================================================

    _fadeTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (_points.value.isEmpty) {
          return;
        }

        final now = DateTime.now();

        final filtered = _points.value.where((point) {
          return now.difference(point.time) < trailDuration;
        }).toList();

        if (filtered.length != _points.value.length) {
          _points.value = filtered;
        }
      },
    );
  }

  @override
  void dispose() {
    _fadeTimer.cancel();
    _animationController.dispose();
    _points.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      // ==========================================================
      // START
      // ==========================================================

      onPanStart: (details) {
        _points.value = [
          TrailPoint(
            details.localPosition,
            DateTime.now(),
          ),
        ];
      },

      // ==========================================================
      // UPDATE
      // ==========================================================

      onPanUpdate: (details) {
        final now = DateTime.now();

        _points.value = [
          ..._points.value,
          TrailPoint(
            details.localPosition,
            now,
          ),
        ];
      },

      // ==========================================================
      // PAINT
      // ==========================================================

      child: ValueListenableBuilder<List<TrailPoint>>(
        valueListenable: _points,
        builder: (_, points, __) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) {
              return CustomPaint(
                size: Size.infinite,
                painter: _MagicTrailPainter(
                  points: points,
                  lineColor: widget.color,
                  sparkleAngle: _animationController.value * 2 * pi,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MagicTrailPainter extends CustomPainter {
  final List<TrailPoint> points;
  final Color lineColor;
  final double sparkleAngle;

  static const double sparkleRadius = 15;

  _MagicTrailPainter({
    required this.points,
    required this.lineColor,
    required this.sparkleAngle,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (points.isEmpty) {
      return;
    }

    // ============================================================
    // TRAIL
    // ============================================================

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final now = DateTime.now();

    for (int i = 0; i < points.length - 1; i++) {
      final point = points[i];
      final nextPoint = points[i + 1];

      // ----------------------------------------------------------
      // AGE
      // ----------------------------------------------------------

      final age = now.difference(point.time);

      final ageProgress =
          age.inMicroseconds / MagicTrailLayer.trailDuration.inMicroseconds;

      // ----------------------------------------------------------
      // FADE
      // ----------------------------------------------------------

      final opacity = (1.0 - ageProgress).clamp(0.0, 1.0);

      paint.color = lineColor.withOpacity(opacity);

      canvas.drawLine(
        point.position,
        nextPoint.position,
        paint,
      );
    }

    // ============================================================
    // HEAD
    // ============================================================

    final head = points.last.position;

    _drawStarShape(
      canvas,
      head,
    );

    _drawRotatingMiniStars(
      canvas,
      head,
    );
  }

  // ==============================================================
  // HEAD
  // ==============================================================

  void _drawStarShape(
    Canvas canvas,
    Offset position,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      position,
      6,
      paint,
    );
  }

  // ==============================================================
  // MINI STARS
  // ==============================================================

  void _drawRotatingMiniStars(
    Canvas canvas,
    Offset center,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = sparkleAngle + (i * 2 * pi / 3);

      final position = Offset(
        center.dx + sparkleRadius * cos(angle),
        center.dy + sparkleRadius * sin(angle),
      );

      _drawMiniStar(
        canvas,
        position,
        paint,
      );
    }
  }

  // ==============================================================
  // MINI STAR SHAPE
  // ==============================================================

  void _drawMiniStar(
    Canvas canvas,
    Offset position,
    Paint paint,
  ) {
    final path = Path();

    const outerRadius = 7.0;
    const innerRadius = 2.0;

    for (int i = 0; i < 10; i++) {
      final angle = pi / 5 * i;

      final radius = i.isEven ? outerRadius : innerRadius;

      final x = position.dx + radius * cos(angle);

      final y = position.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MagicTrailPainter oldDelegate,
  ) {
    return true;
  }
}
