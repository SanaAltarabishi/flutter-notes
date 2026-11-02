import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freenotes_app/features/notes/domain/entities/content_block.dart';

/// ONE place that decides how a TextBlock is laid out.
/// The painter, the selection box and the touch test must all use it.
class TextBlockLayout {
  TextBlockLayout._();

  /// Width used by blocks that have no width saved.
  static const double defaultWidth = 220;

  /// The width the text wraps at: the block's OWN width, but never wider
  /// than what is left up to the right edge of the canvas.
  static double wrapWidth(TextBlock block, {required double canvasRight}) {
    final own = block.width > 0 ? block.width : defaultWidth;
    final room = canvasRight - block.x;
    return room > 0 ? math.min(own, room) : own;
  }

  static TextPainter painterFor(TextBlock block, {required double canvasRight}) {
    return TextPainter(
      text: TextSpan(
        text: block.text,
        style: TextStyle(
          fontFamily: block.fontFamily,
          fontSize: block.fontSize,
          color: Color(block.colorValue),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: wrapWidth(block, canvasRight: canvasRight));
  }

  /// The rectangle the text covers (also used for the selection box).
  static Rect boundsOf(TextBlock block, {required double canvasRight}) {
    final painter = painterFor(block, canvasRight: canvasRight);
    return Rect.fromLTWH(block.x, block.y, painter.width, painter.height);
  }
}