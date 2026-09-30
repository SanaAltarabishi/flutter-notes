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
      if (block is TextBlock) _drawText(canvas, block);
    }
    _drawStrokes(canvas, strokes);

    for (final block in blocks) {
      if (selectedBlockIds.contains(block.id)) {
        _drawSelectionOutline(canvas, _blockBounds(block));
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
          marqueeRect!, Paint()..color = Colors.blue.withOpacity(0.08));
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

  void _drawStrokes(Canvas canvas, List<Stroke> list) {
    for (final stroke in list) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawText(Canvas canvas, TextBlock block) {
    _textPainterFor(block).paint(canvas, Offset(block.x, block.y));
  }


  TextPainter _textPainterFor(TextBlock block) {
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
    painter.layout(maxWidth: block.width > 0 ? block.width : 220);
    return painter;
  }

  // ---- حدود العناصر (لإطار التحديد) ----

  Rect _blockBounds(ContentBlock block) {
    if (block is InkBlock) {
      return _strokesBounds(block.strokes) ??
          Rect.fromLTWH(block.x, block.y, 0, 0);
    }
    if (block is TextBlock) {
      final painter = _textPainterFor(block);
      return Rect.fromLTWH(block.x, block.y, painter.width, painter.height);
    }
    return Rect.fromLTWH(block.x, block.y, block.width, block.height);
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
      ..color = Colors.blue
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
