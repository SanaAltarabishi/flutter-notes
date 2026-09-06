import 'package:flutter/material.dart';
import '../../domain/entities/stroke.dart';
//todo : fix this !! why the material in here ?
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
      points: stroke.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      colorValue: stroke.color.toARGB32(),
      strokeWidth: stroke.strokeWidth,
      createdAtMillis: stroke.createdAt.millisecondsSinceEpoch,
    );
  }
//_______________________________________________
  Stroke toEntity() {
    return Stroke(
      id: id,
      points: points.map((p) => Offset(p['x']!, p['y']!)).toList(),
      color: Color.fromARGB(//4*8 > 32 bits
        (colorValue >> 24) & 0xFF,//alpha: transparency ( 0 → 255), 0xFF = 255 , & 0xFF =give me only the last 8 bits, >> shift right 24 bits
        (colorValue >> 16) & 0xFF,//red
        (colorValue >> 8) & 0xFF,//green
        colorValue & 0xFF,//blue
      ),
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
