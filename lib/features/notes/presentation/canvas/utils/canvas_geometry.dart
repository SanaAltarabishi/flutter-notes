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