import 'package:equatable/equatable.dart';
import 'package:freenotes_app/features/notes/domain/entities/stroke_point.dart';

class Stroke extends Equatable {
  final String id;
  final List<StrokePoint> points;
  //final Color color;
  final int colorValue;
  final double strokeWidth;
  final DateTime createdAt;

  const Stroke({
    required this.id,
    required this.points,
    required this.colorValue,
    this.strokeWidth = 2.0,
    required this.createdAt,
  });

  Stroke copyWith({
    String? id,
    List<StrokePoint>? points,
    int? colorValue,
    double? strokeWidth,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, points, colorValue, strokeWidth, createdAt];
}
