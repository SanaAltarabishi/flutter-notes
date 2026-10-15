import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import '../../../domain/entities/stroke.dart';
import '../../../domain/entities/content_block.dart';

class DrawingCanvas extends StatelessWidget {
  final List<Stroke> strokes;
  final List<ContentBlock> blocks;
  final Set<String> selectedBlockIds;
  final Set<String> selectedStrokeIds;
  final Rect? marqueeRect;
  final void Function(Offset) onStart;
  final void Function(Offset) onUpdate;
  final void Function() onEnd;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.blocks = const [],
    this.selectedBlockIds = const {},
    this.selectedStrokeIds = const {},
    this.marqueeRect,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onStart(details.localPosition),
      onPanUpdate: (details) => onUpdate(details.localPosition),
      onPanEnd: (_) => onEnd(),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CanvasPainter(
            strokes: strokes,
            blocks: blocks,
            selectedBlockIds: selectedBlockIds,
            selectedStrokeIds: selectedStrokeIds,
            marqueeRect: marqueeRect,
          ),
        ),
      ),
    );
  }
}

//___________________________________________________
class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<ContentBlock> blocks;
  final Set<String> selectedBlockIds;
  final Set<String> selectedStrokeIds;
  final Rect? marqueeRect;

  _CanvasPainter({
    required this.strokes,
    required this.blocks,
    this.selectedBlockIds = const {},
    this.selectedStrokeIds = const {},
    this.marqueeRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.white);
    _drawGrid(canvas, size);

    for (final block in blocks) {
      if (block is InkBlock) _drawStrokes(canvas, block.strokes);
      if (block is TextBlock) _drawText(canvas, size, block);
    }
    _drawStrokes(canvas, strokes);

    for (final block in blocks) {
      if (block is! InkBlock) continue;
      final selected = block.strokes
          .where((stroke) => selectedStrokeIds.contains(stroke.id))
          .toList();
      final bounds = _strokesBounds(selected);
      if (bounds != null) _drawSelectionOutline(canvas, bounds);
    }

    for (final block in blocks) {
      if (selectedBlockIds.contains(block.id)) {
        _drawSelectionOutline(canvas, _blockBounds(block, size));
      }
    }

    if (selectedStrokeIds.isNotEmpty) {
      final selected =
          strokes.where((s) => selectedStrokeIds.contains(s.id)).toList();
      final bounds = _strokesBounds(selected);
      if (bounds != null) _drawSelectionOutline(canvas, bounds);
    }

    if (marqueeRect != null) {
      canvas.drawRect(
          marqueeRect!, Paint()..color = AppColors.canvasSelection);
      _drawSelectionOutline(canvas, marqueeRect!);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bookPageBackground
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  // void _drawStrokes(Canvas canvas, List<Stroke> list) {
  //   for (final stroke in list) {
  //     if (stroke.points.length < 2) continue;

  //     final paint = Paint()
  //       ..color = Color(stroke.colorValue)
  //       ..strokeWidth = stroke.strokeWidth
  //       ..strokeCap = StrokeCap.round
  //       ..strokeJoin = StrokeJoin.round
  //       ..style = PaintingStyle.stroke;

  //     final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
  //     for (final p in stroke.points.skip(1)) {
  //       path.lineTo(p.x, p.y);
  //     }
  //     canvas.drawPath(path, paint);
  //   }
  // }
  void _drawStrokes(Canvas canvas, List<Stroke> list) {
    for (final stroke in list) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      final points = stroke.points.map((p) => Offset(p.x, p.y)).toList();

      final path = Path();

      path.moveTo(points.first.dx, points.first.dy);

      if (points.length == 2) {
        path.lineTo(points.last.dx, points.last.dy);
        canvas.drawPath(path, paint);
        continue;
      }

      // Smooth the stroke using quadratic Bézier curves.
      for (int i = 1; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];

        final midpoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );

        path.quadraticBezierTo(
          current.dx, // يتحكم في الانحناء
          current.dy,
          midpoint.dx, //اين ينتهي الانحناء
          midpoint.dy,
        );
      }

      // Finish at the last point.
      final last = points.last;
      final previous = points[points.length - 2];

      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        last.dx,
        last.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  void _drawText(Canvas canvas, Size size, TextBlock block) {
    final availableWidth = (size.width - block.x).clamp(0.0, double.infinity);

    final painter = _textPainterFor(
      block,
      maxWidth: availableWidth,
    );

    painter.paint(
      canvas,
      Offset(block.x, block.y),
    );
  }

  TextPainter _textPainterFor(TextBlock block,
      {double maxWidth = double.infinity}) {
    final painter = TextPainter(
      text: TextSpan(
        text: block.text,
        style: TextStyle(
          fontFamily: block.fontFamily,
          fontSize: block.fontSize,
          color: Color(block.colorValue),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: maxWidth); //block.width > 0 ? block.width : 220);
    return painter;
  }

  // ---- حدود العناصر (لإطار التحديد) ----

  Rect _blockBounds(
    ContentBlock block,
    Size size,
  ) {
    if (block is InkBlock) {
      return _strokesBounds(block.strokes) ??
          Rect.fromLTWH(block.x, block.y, 0, 0);
    }

    if (block is TextBlock) {
      final availableWidth = (size.width - block.x).clamp(0.0, double.infinity);

      final painter = _textPainterFor(
        block,
        maxWidth: availableWidth,
      );

      return Rect.fromLTWH(
        block.x,
        block.y,
        painter.width,
        painter.height,
      );
    }

    return Rect.fromLTWH(
      block.x,
      block.y,
      block.width,
      block.height,
    );
  }

  Rect? _strokesBounds(List<Stroke> list) {
    Rect? bounds;
    for (final stroke in list) {
      if (stroke.points.isEmpty) continue;
      final points = stroke.points.map((p) => Offset(p.x, p.y));
      final strokeBounds =
          _pointsBounds(points).inflate(stroke.strokeWidth / 2);
      bounds = bounds?.expandToInclude(strokeBounds) ?? strokeBounds;
    }
    return bounds;
  }

  Rect _pointsBounds(Iterable<Offset> points) {
    final xs = points.map((p) => p.dx);
    final ys = points.map((p) => p.dy);
    return Rect.fromLTRB(
      xs.reduce((a, b) => a < b ? a : b),
      ys.reduce((a, b) => a < b ? a : b),
      xs.reduce((a, b) => a > b ? a : b),
      ys.reduce((a, b) => a > b ? a : b),
    );
  }

  void _drawSelectionOutline(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0, dashSpace = 4.0;
    final dashPath = Path();

    for (final metric in (Path()..addRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
