import 'dart:convert';
import '../../domain/entities/content_block.dart';
import 'stroke_model.dart';

class ContentBlockModel {
  final String id;
  final String pageId;
  final String type;
  final int orderIndex;
  final double x;
  final double y;
  final double width;
  final double height;
  final String data; // JSON string
  final int createdAtMillis;
  final int updatedAtMillis;

  ContentBlockModel({
    required this.id,
    required this.pageId,
    required this.type,
    required this.orderIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.data,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });
//__________________________________________________________
  factory ContentBlockModel.fromEntity(ContentBlock block) {
    String data;
    if (block is InkBlock) {
      data = jsonEncode({
        'strokes': block.strokes
            .map((s) => StrokeModel.fromEntity(s).toMap())
            .toList(),
        'recognizedText': block.recognizedText,
      });
    } else if (block is TextBlock) {
      data = jsonEncode({
        'text': block.text,
        'fontFamily': block.fontFamily,
        'colorValue': block.colorValue,
        'fontSize': block.fontSize,
      });
    } else if (block is ImageBlock) {
      data = jsonEncode({'imagePath': block.imagePath});
    } else {
      data = '{}';
    }

    return ContentBlockModel(
      id: block.id,
      pageId: block.pageId,
      type: block.type,
      orderIndex: block.orderIndex,
      x: block.x,
      y: block.y,
      width: block.width,
      height: block.height,
      data: data,
      createdAtMillis: block.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: block.updatedAt.millisecondsSinceEpoch,
    );
  }
//__________________________________________________________

  ContentBlock toEntity() {
    final decodedData = jsonDecode(data) as Map<String, dynamic>;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);

    switch (type) {
      case 'ink':
        final strokesJson = decodedData['strokes'] as List? ?? [];
        return InkBlock(
          id: id,
          pageId: pageId,
          orderIndex: orderIndex,
          x: x,
          y: y,
          width: width,
          height: height,
          strokes: strokesJson
              .map((s) => StrokeModel.fromMap(s).toEntity())
              .toList(),
          recognizedText: decodedData['recognizedText'] as String?,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      case 'text':
        return TextBlock(
          id: id,
          pageId: pageId,
          orderIndex: orderIndex,
          x: x,
          y: y,
          width: width,
          height: height,
          text: decodedData['text'] as String? ?? '',
          fontFamily: decodedData['fontFamily'] as String? ?? 'Roboto',
          colorValue: decodedData['colorValue'] as int? ?? 0xFF000000,
          fontSize: (decodedData['fontSize'] as num?)?.toDouble() ?? 16.0,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      case 'image':
        return ImageBlock(
          id: id,
          pageId: pageId,
          orderIndex: orderIndex,
          x: x,
          y: y,
          width: width,
          height: height,
          imagePath: decodedData['imagePath'] as String? ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      default:
        return InkBlock(
          id: id,
          pageId: pageId,
          orderIndex: orderIndex,
          strokes: const [],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
    }
  }
//__________________________________________________________
  Map<String, dynamic> toMap() => {
        'id': id,
        'page_id': pageId,
        'type': type,
        'order_index': orderIndex,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'data': data,
        'created_at': createdAtMillis,
        'updated_at': updatedAtMillis,
      };
//__________________________________________________________
  factory ContentBlockModel.fromMap(Map<String, dynamic> map) {
    return ContentBlockModel(
      id: map['id'] as String,
      pageId: map['page_id'] as String,
      type: map['type'] as String,
      orderIndex: map['order_index'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      data: map['data'] as String,
      createdAtMillis: map['created_at'] as int,
      updatedAtMillis: map['updated_at'] as int,
    );
  }
}
