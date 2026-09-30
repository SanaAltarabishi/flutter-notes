import 'package:flutter/material.dart';
import '../../features/notes/domain/entities/content_block.dart';

TextDirection textDirectionFor(String text) {
  for (final rune in text.runes) {
    final isArabicOrHebrew = (rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFEFF);
    if (isArabicOrHebrew) return TextDirection.rtl;

    final isLatin =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    if (isLatin) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

TextPainter buildTextPainter({
  required String text,
  required String fontFamily,
  required double fontSize,
  required Color color,
  required double width,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        color: color,
        height: 1.3,
      ),
    ),
    textDirection: textDirectionFor(text),
  );
  painter.layout(minWidth: width, maxWidth: width);
  return painter;
}

double measureNaturalWidth({
  required String text,
  required String fontFamily,
  required double fontSize,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: fontFamily, fontSize: fontSize),
    ),
    textDirection: textDirectionFor(text),
  )..layout();
  return painter.width;
}

double measureTextHeight({
  required String text,
  required String fontFamily,
  required double fontSize,
  required double width,
}) {
  final painter = buildTextPainter(
    text: text,
    fontFamily: fontFamily,
    fontSize: fontSize,
    color: Colors.black,
    width: width,
  );
  return painter.height + 8;
}

const double kDefaultTextWidth = 220;
const double kMinTextWidth = 60;
const double kMaxTextWidth = 520;

TextBlock rebuildTextBlock(
  TextBlock block, {
  String? text,
  double? fontSize,
  int? colorValue,
  double? x,
  double? y,
}) {
  final newText = text ?? block.text;
  final newFontSize = fontSize ?? block.fontSize;
  final contentChanged = text != null || fontSize != null;

  final width = contentChanged
      ? (measureNaturalWidth(
                text: newText,
                fontFamily: block.fontFamily,
                fontSize: newFontSize,
              ) +
              16)
          .clamp(kMinTextWidth, kMaxTextWidth)
      : (block.width > 0 ? block.width : kDefaultTextWidth);

  return TextBlock(
    id: block.id,
    pageId: block.pageId,
    orderIndex: block.orderIndex,
    x: x ?? block.x,
    y: y ?? block.y,
    width: width,
    height: measureTextHeight(
      text: newText,
      fontFamily: block.fontFamily,
      fontSize: newFontSize,
      width: width,
    ),
    text: newText,
    fontFamily: block.fontFamily,
    colorValue: colorValue ?? block.colorValue,
    fontSize: newFontSize,
    createdAt: block.createdAt,
    updatedAt: DateTime.now(),
  );
}