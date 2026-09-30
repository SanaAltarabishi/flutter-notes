import 'package:flutter/material.dart';
import '../../../domain/entities/stroke.dart';
import '../../../domain/entities/stroke_point.dart';

//todo : understand this code
class StrokeEraser {
  const StrokeEraser._();

  static List<Stroke> eraseFromStroke({
    required Stroke stroke,
    required Offset erasePoint,
    required double radius,
  }) {
    final segments = <List<StrokePoint>>[[]];

    var anyRemoved = false;

    for (final point in stroke.points) {
      final dx = point.x - erasePoint.dx;
      final dy = point.y - erasePoint.dy;

      final distanceSquared = dx * dx + dy * dy;

      final isInside = distanceSquared <= radius * radius;

      if (isInside) {
        anyRemoved = true;

        if (segments.last.isNotEmpty) {
          segments.add([]);
        }
      } else {
        segments.last.add(point);
      }
    }

    if (!anyRemoved) {
      return [stroke];
    }

    final result = <Stroke>[];

    for (var i = 0; i < segments.length; i++) {
      final points = segments[i];

      if (points.length < 2) {
        continue;
      }

      result.add(
        Stroke(
          id: '${stroke.id}_e$i',
          points: points,
          colorValue: stroke.colorValue,
          strokeWidth: stroke.strokeWidth,
          createdAt: stroke.createdAt,
        ),
      );
    }

    return result;
  }

//____________________________________________________
  static List<Stroke> eraseFromStrokes({
    required List<Stroke> strokes,
    required Offset erasePoint,
    required double radius,
  }) {
    final result = <Stroke>[];

    for (final stroke in strokes) {
      result.addAll(
        eraseFromStroke(
          stroke: stroke,
          erasePoint: erasePoint,
          radius: radius,
        ),
      );
    }

    return result;
  }
}
