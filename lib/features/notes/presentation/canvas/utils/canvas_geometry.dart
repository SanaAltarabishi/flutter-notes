import 'package:flutter/material.dart';
import '../../../domain/entities/content_block.dart';
import '../../../domain/entities/stroke.dart';

class CanvasGeometry {
  const CanvasGeometry._();

  static Rect blockRect(ContentBlock block) {
    return Rect.fromLTWH(
      block.x,
      block.y,
      block.width,
      block.height,
    );
  }

  static Rect? strokesBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    var hasPoints = false;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        hasPoints = true;

        if (point.x < minX) minX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.x > maxX) maxX = point.x;
        if (point.y > maxY) maxY = point.y;
      }
    }

    if (!hasPoints) return null;

    return Rect.fromLTRB(
      minX,
      minY,
      maxX,
      maxY,
    );
  }

  static Rect? selectedStrokesBounds(
    List<Stroke> strokes,
    Set<String> selectedStrokeIds,
  ) {
    final selected = strokes
        .where((stroke) => selectedStrokeIds.contains(stroke.id))
        .toList();

    return strokesBounds(selected);
  }

  static bool strokeIntersectsRect(Stroke stroke, Rect rect) {
    if (stroke.points.isEmpty) return false;

    final hitRect = rect.inflate(stroke.strokeWidth / 2);
    for (var index = 0; index < stroke.points.length; index++) {
      final point = stroke.points[index];
      final current = Offset(point.x, point.y);
      if (hitRect.contains(current)) return true;

      if (index == 0) continue;
      final previousPoint = stroke.points[index - 1];
      final previous = Offset(previousPoint.x, previousPoint.y);
      if (_segmentIntersectsRect(previous, current, hitRect)) return true;
    }

    return false;
  }

  static bool _segmentIntersectsRect(Offset start, Offset end, Rect rect) {
    if (rect.contains(start) || rect.contains(end)) return true;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    var tMin = 0.0;
    var tMax = 1.0;

    bool clip(double startValue, double delta, double min, double max) {
      if (delta == 0) return startValue >= min && startValue <= max;

      var t1 = (min - startValue) / delta;
      var t2 = (max - startValue) / delta;
      if (t1 > t2) {
        final swap = t1;
        t1 = t2;
        t2 = swap;
      }
      tMin = tMin > t1 ? tMin : t1;
      tMax = tMax < t2 ? tMax : t2;
      return tMin <= tMax;
    }

    return clip(start.dx, dx, rect.left, rect.right) &&
        clip(start.dy, dy, rect.top, rect.bottom);
  }

  static Rect? selectionBounds({
    required List<ContentBlock> blocks,
    required List<Stroke> strokes,
    required Set<String> selectedBlockIds,
    required Set<String> selectedStrokeIds,
  }) {
    Rect? result;

    for (final block in blocks) {
      if (!selectedBlockIds.contains(block.id)) continue;

      final rect = blockRect(block);

      result = result == null
          ? rect
          : result.expandToInclude(rect);
    }

    final strokeBounds = selectedStrokesBounds(
      strokes,
      selectedStrokeIds,
    );

    if (strokeBounds != null) {
      result = result == null
          ? strokeBounds
          : result.expandToInclude(strokeBounds);
    }

    return result;
  }
}