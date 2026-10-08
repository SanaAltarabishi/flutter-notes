import 'package:equatable/equatable.dart';
import 'content_block.dart';

class NotePage extends Equatable {
  final String id;
  final String bookId;
  final String name;
  final int orderIndex;
  final List<ContentBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotePage({
    required this.id,
    required this.bookId,
    this.name = '',
    required this.orderIndex,
    this.blocks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  NotePage copyWith({
    String? id,
    String? bookId,
    String? name,
    int? orderIndex,
    List<ContentBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotePage(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, bookId, name, orderIndex, blocks];
}
