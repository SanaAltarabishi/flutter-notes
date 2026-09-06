import '../../domain/entities/page.dart';
import 'content_block_model.dart';

class PageModel {
  final String id;
  final String bookId;
  final int orderIndex;
  final int createdAtMillis;
  final int updatedAtMillis;

  PageModel({
    required this.id,
    required this.bookId,
    required this.orderIndex,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });
//_______________________________________________
  factory PageModel.fromEntity(NotePage page) {
    return PageModel(
      id: page.id,
      bookId: page.bookId,
      orderIndex: page.orderIndex,
      createdAtMillis: page.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: page.updatedAt.millisecondsSinceEpoch,
    );
  }
//_______________________________________________
  NotePage toEntity({List<ContentBlockModel>? blockModels}) {
    return NotePage(
      id: id,
      bookId: bookId,
      orderIndex: orderIndex,
      blocks: blockModels?.map((b) => b.toEntity()).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }
//_______________________________________________
  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'order_index': orderIndex,
        'created_at': createdAtMillis,
        'updated_at': updatedAtMillis,
      };
//_______________________________________________
  factory PageModel.fromMap(Map<String, dynamic> map) {
    return PageModel(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      orderIndex: map['order_index'] as int,
      createdAtMillis: map['created_at'] as int,
      updatedAtMillis: map['updated_at'] as int,
    );
  }
}
