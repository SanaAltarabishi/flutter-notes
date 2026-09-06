import 'package:equatable/equatable.dart';
import 'content_block.dart';

class NotePage extends Equatable {
  final String id;
  final String bookId;
  final int orderIndex;
  final List<ContentBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotePage({
    required this.id,
    required this.bookId,
    required this.orderIndex,
    this.blocks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  NotePage copyWith({
    String? id,
    String? bookId,
    int? orderIndex,
    List<ContentBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotePage(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      orderIndex: orderIndex ?? this.orderIndex,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, bookId, orderIndex, blocks];
}
