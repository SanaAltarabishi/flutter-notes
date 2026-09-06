import '../../domain/entities/book.dart';

class BookModel {
  final String id;
  final String title;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int coverColorValue;

  BookModel({
    required this.id,
    required this.title,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.coverColorValue = 0xFF2196F3,
  });
//__________________________________________________________

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      createdAtMillis: book.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: book.updatedAt.millisecondsSinceEpoch,
      coverColorValue: book.coverColorValue,
    );
  }
//__________________________________________________________

  Book toEntity() {
    return Book(
      id: id,
      title: title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
      coverColorValue: coverColorValue,
    );
  }
//__________________________________________________________

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAtMillis,
        'updated_at': updatedAtMillis,
        'cover_color': coverColorValue,
      };
//__________________________________________________________
  factory BookModel.fromMap(Map<String, dynamic> map) {
    //here it not nessary to use the factory
    return BookModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAtMillis: map['created_at'] as int,
      updatedAtMillis: map['updated_at'] as int,
      coverColorValue: map['cover_color'] as int? ?? 0xFF2196F3,
    );
  }
}
