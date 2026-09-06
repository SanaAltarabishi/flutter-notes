import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int coverColorValue;

  const Book({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.coverColorValue = 0xFF2196F3,
  });

  Book copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? coverColorValue,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverColorValue: coverColorValue ?? this.coverColorValue,
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, coverColorValue];
}
