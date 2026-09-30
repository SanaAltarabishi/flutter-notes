import 'package:equatable/equatable.dart';

class StrokePoint extends Equatable {
  final double x;
  final double y;

  const StrokePoint({
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [x, y];
}