import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Stroke extends Equatable {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DateTime createdAt;

  const Stroke({
    required this.id,
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
    required this.createdAt,
  });

  Stroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, points, color, strokeWidth, createdAt];
}
