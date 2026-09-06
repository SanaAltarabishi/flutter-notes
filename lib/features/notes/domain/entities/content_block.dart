import 'package:equatable/equatable.dart';
import 'stroke.dart';

abstract class ContentBlock extends Equatable {
  final String id;
  final String pageId;
  final int orderIndex;
  final double x;
  final double y;
  final double width;
  final double height;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentBlock({
    required this.id,
    required this.pageId,
    required this.orderIndex,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get type;
}

//___________________________________________________
class InkBlock extends ContentBlock {
  final List<Stroke> strokes;
  final String? recognizedText;

  const InkBlock({
    required super.id,
    required super.pageId,
    required super.orderIndex,
    super.x,
    super.y,
    super.width,
    super.height,
    required this.strokes,
    this.recognizedText,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  String get type => 'ink';

  InkBlock copyWith({
    String? id,
    String? pageId,
    int? orderIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    List<Stroke>? strokes,
    String? recognizedText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InkBlock(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      orderIndex: orderIndex ?? this.orderIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      strokes: strokes ?? this.strokes,
      recognizedText: recognizedText ?? this.recognizedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, pageId, orderIndex, strokes, recognizedText, type];
}

//_____________________________________________________
class TextBlock extends ContentBlock {
  final String text;
  final String fontFamily;
  final int colorValue;
  final double fontSize;

  const TextBlock({
    required super.id,
    required super.pageId,
    required super.orderIndex,
    super.x,
    super.y,
    super.width,
    super.height,
    required this.text,
    this.fontFamily = 'Roboto',
    this.colorValue = 0xFF000000,
    this.fontSize = 16.0,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  String get type => 'text';

  TextBlock copyWith({
    String? id,
    String? pageId,
    int? orderIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    String? fontFamily,
    int? colorValue,
    double? fontSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TextBlock(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      orderIndex: orderIndex ?? this.orderIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      colorValue: colorValue ?? this.colorValue,
      fontSize: fontSize ?? this.fontSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, text, fontFamily, colorValue, fontSize, type];
}
//_____________________________________________________
class ImageBlock extends ContentBlock {
  final String imagePath;

  const ImageBlock({
    required super.id,
    required super.pageId,
    required super.orderIndex,
    super.x,
    super.y,
    super.width,
    super.height,
    required this.imagePath,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  String get type => 'image';

  ImageBlock copyWith({
    String? id,
    String? pageId,
    int? orderIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImageBlock(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      orderIndex: orderIndex ?? this.orderIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, imagePath, type];
}
