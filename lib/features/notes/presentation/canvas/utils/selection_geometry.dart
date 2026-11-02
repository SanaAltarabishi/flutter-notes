import 'package:flutter/material.dart';
import 'package:freenotes_app/features/notes/domain/entities/content_block.dart';
import 'package:freenotes_app/features/notes/domain/entities/stroke.dart';
import 'text_block_layout.dart';

/// One rectangle around EVERYTHING that is selected.
///
/// Your painter draws one dashed box per item. The resize handles need ONE
/// box for the whole selection, so this computes the union.
/// The math is the same as `_strokesBounds` / `_blockBounds` in
/// `_CanvasPainter`, so the handles sit exactly on the dashed outline.
class SelectionGeometry {
  SelectionGeometry._();

  static Rect? boundsOf({
    required List<Stroke> strokes,
    required List<ContentBlock> blocks,
    required Set<String> selectedBlockIds,
    required Set<String> selectedStrokeIds,
    required Size page,
  }) {
    Rect? bounds;
    void add(Rect? r) {
      if (r == null) return;
      bounds = bounds?.expandToInclude(r) ?? r;
    }

    for (final block in blocks) {
      if (block is InkBlock) {
        final wholeBlock = selectedBlockIds.contains(block.id);
        add(_strokesBounds(wholeBlock
            ? block.strokes
            : block.strokes.where((s) => selectedStrokeIds.contains(s.id))));
      } else if (block is TextBlock) {
        if (selectedBlockIds.contains(block.id)) add(_textBounds(block, page));
      } else if (selectedBlockIds.contains(block.id)) {
        add(Rect.fromLTWH(block.x, block.y, block.width, block.height));
      }
    }

    add(_strokesBounds(strokes.where((s) => selectedStrokeIds.contains(s.id))));
    return bounds;
  }

  /// True when a text block is part of the selection.
  /// Text can only be scaled uniformly, so edge handles are hidden then.
  static bool containsText({
    required List<ContentBlock> blocks,
    required Set<String> selectedBlockIds,
  }) =>
      blocks.any((b) => b is TextBlock && selectedBlockIds.contains(b.id));

  static Rect? _strokesBounds(Iterable<Stroke> list) {
    Rect? bounds;
    for (final stroke in list) {
      if (stroke.points.isEmpty) continue;
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (final p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      final r =
          Rect.fromLTRB(minX, minY, maxX, maxY).inflate(stroke.strokeWidth / 2);
      bounds = bounds?.expandToInclude(r) ?? r;
    }
    return bounds;
  }

  // // Same layout as the painter's _textPainterFor.
  // static Rect _textBounds(TextBlock block, Size page) {
  //   final availableWidth = (page.width - block.x).clamp(0.0, double.infinity);
  //   final painter = TextPainter(
  //     text: TextSpan(
  //       text: block.text,
  //       style: TextStyle(
  //         fontFamily: block.fontFamily,
  //         fontSize: block.fontSize,
  //         color: Color(block.colorValue),
  //       ),
  //     ),
  //     textDirection: TextDirection.ltr,
  //   )..layout(maxWidth: availableWidth);
  //   return Rect.fromLTWH(block.x, block.y, painter.width, painter.height);
  // }
  // Same layout as the painter: see TextBlockLayout.
  static Rect _textBounds(TextBlock block, Size page) =>
      TextBlockLayout.boundsOf(block, canvasRight: page.width);
}
