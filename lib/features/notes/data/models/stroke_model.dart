import '../../domain/entities/stroke.dart';
import '../../domain/entities/stroke_point.dart';

class StrokeModel {
  final String id;
  final List<Map<String, double>> points;
  final int colorValue;
  final double strokeWidth;
  final int createdAtMillis;

  StrokeModel({
    required this.id,
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    required this.createdAtMillis,
  });
//_______________________________________________
  factory StrokeModel.fromEntity(Stroke stroke) {
    return StrokeModel(
      id: stroke.id,
      points: stroke.points.map((p) => {'x': p.x, 'y': p.y}).toList(),
      colorValue: stroke.colorValue,
      strokeWidth: stroke.strokeWidth,
      createdAtMillis: stroke.createdAt.millisecondsSinceEpoch,
    );
  }
//_______________________________________________
  Stroke toEntity() {
    return Stroke(
      id: id,
      points: points.map((p) => StrokePoint(x: p['x']!, y: p['y']!)).toList(),
      colorValue: colorValue,
      strokeWidth: strokeWidth,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
    );
  }

//_______________________________________________
  Map<String, dynamic> toMap() => {
        'id': id,
        'points': points,
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
        'createdAtMillis': createdAtMillis,
      };
//_______________________________________________
  factory StrokeModel.fromMap(Map<String, dynamic> map) {
    return StrokeModel(
      id: map['id'] as String,
      points: (map['points'] as List)
          .map((p) => {
                'x': (p['x'] as num).toDouble(),
                'y': (p['y'] as num).toDouble(),
              })
          .toList(),
      colorValue: map['colorValue'] as int,
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
      createdAtMillis: map['createdAtMillis'] as int,
    );
  }
}
