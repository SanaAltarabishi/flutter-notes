import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/text_utils.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/entities/stroke_point.dart';
import '../../domain/usecases/blocks/delete_block.dart';
import '../../domain/usecases/blocks/get_blocks.dart';
import '../../domain/usecases/blocks/save_block.dart';
import '../../domain/usecases/handwriting/convert_handwriting.dart';
import 'canvas_state.dart';
import '../providers/core_providers.dart';
import 'utils/canvas_geometry.dart';
import 'utils/canvas_history.dart';
import 'utils/resize_handle_position.dart';
import 'utils/selection_geometry.dart';
import 'utils/selection_resize.dart';
import 'utils/stroke_eraser.dart';
import 'utils/text_block_layout.dart';

/// The 4 sides of the canvas.
enum _Edge { left, top, right, bottom }

final canvasProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, String>(
        CanvasNotifier.new);

class CanvasNotifier extends FamilyNotifier<CanvasState, String> {
  late final String pageId;
  static const double _defaultTextWidth = TextBlockLayout.defaultWidth;
  static const double _defaultFontSize = 18;
  static const String _defaultFont = 'Roboto';

  final CanvasHistory _history = CanvasHistory();

  Offset? _lastDragPoint;
  Offset? _marqueeStart;
  bool _isDraggingSelection = false;
  bool _dragMoved = false;
  bool _dragSnapshotTaken = false;

  List<Stroke>? _resizeStartStrokes; // snapshot taken when the drag starts
  List<ContentBlock>? _resizeStartBlocks;
  Rect? _resizeStartBounds;
  bool _resizeSnapshotTaken = false; // undo snapshot, only if something changed
  bool _resizeMoved = false;

  // ---- Canvas growth ------------------------------------------------------

  /// The canvas grows when the pointer (or the selection) gets this close
  /// to one of its edges.
  static const double _expansionThreshold = 50;

  /// How much the canvas grows each time.
  static const double _expansionAmount = 400;

  /// Only these tools can make the canvas grow.
  static const Set<CanvasTool> _expandingTools = {
    CanvasTool.pen,
    CanvasTool.highlighter,
    CanvasTool.lasso,
  };

  /// Edges that just grew and that the pointer has not left yet.
  /// It stops the same edge from growing again and again while the pointer
  /// is still close to it. When the pointer leaves an edge, that edge is
  /// removed from this set and can grow again.
  final Set<_Edge> _spentEdges = {};

  @override
  CanvasState build(String arg) {
    pageId = arg;
    _loadBlocks();
    return const CanvasState();
  }

  Future<void> _loadBlocks() async {
    final getBlocks = ref.read(getBlocksUseCaseProvider);
    final result = await getBlocks(GetBlocksParams(pageId));

    // result.fold(
    //   (failure) => state = state.copyWith(error: failure),
    //   (blocks) => state = state.copyWith(blocks: blocks, clearError: true),
    // );
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (loaded) {
        // 1) Content saved at negative coordinates can not be reached: move it back in.
        final blocks = _bringIntoView(loaded);

        // 2) The canvas size is NOT saved, only the blocks are. Make the canvas
        //    big enough to show everything that was drawn on it.
        state = state.copyWith(
          blocks: blocks,
          canvasSize: _canvasSizeToFit(blocks),
          clearError: true,
        );

        // Save the moved blocks (only when something was moved).
        if (!identical(blocks, loaded)) unawaited(_saveBlocks(blocks));
      },
    );
  }

  // ---- Fit the canvas to the saved content ---------------------------------

  /// The rectangle a block covers (null if it has nothing to show).
  Rect? _contentRect(ContentBlock block) {
    if (block is InkBlock) return CanvasGeometry.strokesBounds(block.strokes);
    if (block is TextBlock) {
      // No right edge yet: the text wraps at its own width.
      return TextBlockLayout.boundsOf(block, canvasRight: double.infinity);
    }
    return Rect.fromLTWH(block.x, block.y, block.width, block.height);
  }

  /// One rectangle around all the blocks (null if there is nothing).
  Rect? _contentBounds(List<ContentBlock> blocks) {
    Rect? bounds;
    for (final block in blocks) {
      final rect = _contentRect(block);
      if (rect != null) bounds = bounds?.expandToInclude(rect) ?? rect;
    }
    return bounds;
  }

  /// If some content is at negative coordinates (left of or above the canvas),
  /// move EVERYTHING right / down so it can be reached again.
  /// Returns the same list if nothing had to move.
  List<ContentBlock> _bringIntoView(List<ContentBlock> blocks) {
    final bounds = _contentBounds(blocks);
    if (bounds == null || (bounds.left >= 0 && bounds.top >= 0)) return blocks;

    const margin = _expansionThreshold * 2;
    final dx = bounds.left < 0 ? margin - bounds.left : 0.0;
    final dy = bounds.top < 0 ? margin - bounds.top : 0.0;

    return [for (final block in blocks) _shiftBlock(block, dx, dy)];
  }

  /// The current canvas size, made bigger if the content goes past it.
  /// It never makes the canvas smaller.
  Size _canvasSizeToFit(List<ContentBlock> blocks) {
    final size = state.canvasSize;
    final bounds = _contentBounds(blocks);
    if (bounds == null) return size;

    const margin =
        _expansionThreshold * 2; // room so the edge does not grow right away
    return Size(
      math.max(size.width, bounds.right + margin),
      math.max(size.height, bounds.bottom + margin),
    );
  }

  void setCanvasSize(Size size) => state = state.copyWith(canvasSize: size);

  // ============================================================
  // Undo / Redo
  void _saveHistory() {
    _history.save(strokes: state.strokes, blocks: state.blocks);
    state =
        state.copyWith(canUndo: _history.canUndo, canRedo: _history.canRedo);
  }

  void _resetHistory() {
    _history.clear();
    state = state.copyWith(canUndo: false, canRedo: false);
  }

  Future<void> undo() async {
    final previous = _history.undo(
      currentStrokes: state.strokes,
      currentBlocks: state.blocks,
    );
    if (previous == null) return;
    final currentBlocks = state.blocks;
    state = state.copyWith(
      strokes: previous.strokes,
      blocks: previous.blocks,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
    await _syncBlocks(currentBlocks, previous.blocks);
  }

  Future<void> redo() async {
    final next = _history.redo(
      currentStrokes: state.strokes,
      currentBlocks: state.blocks,
    );
    if (next == null) return;
    final currentBlocks = state.blocks;
    state = state.copyWith(
      strokes: next.strokes,
      blocks: next.blocks,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
    await _syncBlocks(currentBlocks, next.blocks);
  }

  Future<void> _syncBlocks(
      List<ContentBlock> from, List<ContentBlock> to) async {
    final fromById = {for (final block in from) block.id: block};
    final toById = {for (final block in to) block.id: block};
    final deleteBlock = ref.read(deleteBlockUseCaseProvider);
    final saveBlock = ref.read(saveBlockUseCaseProvider);

    for (final id in fromById.keys) {
      if (toById.containsKey(id)) continue;
      await deleteBlock(DeleteBlockParams(id));
    }
    for (final block in toById.values) {
      if (fromById[block.id] == block) continue;
      await saveBlock(SaveBlockParams(block));
    }
  }

  // ============================================================
  // رسم: قلم / تظليل
  void startStroke(Offset point) {
    _saveHistory();
    _resetExpansion();

    final isHighlighter = state.currentTool == CanvasTool.highlighter;
    final baseColor =
        isHighlighter ? state.highlighterColor : state.currentColor;
    final color = isHighlighter ? baseColor.withOpacity(0.35) : baseColor;
    final width = isHighlighter ? state.highlighterWidth : state.strokeWidth;
    final now = DateTime.now();

    final newStroke = Stroke(
      id: now.millisecondsSinceEpoch.toString(),
      points: [StrokePoint(x: point.dx, y: point.dy)],
      colorValue: color.value,
      strokeWidth: width,
      createdAt: now,
    );

    state = state.copyWith(strokes: [...state.strokes, newStroke]);
  }

  void addPoint(Offset point) {
    if (state.strokes.isEmpty) return;

    final last = state.strokes.last;
    final updated = last.copyWith(
      points: [...last.points, StrokePoint(x: point.dx, y: point.dy)],
    );

    state = state.copyWith(
      strokes: [...state.strokes.sublist(0, state.strokes.length - 1), updated],
    );
  }

  void endStroke() => _resetExpansion();

  void setHighlighterWidth(double width) =>
      state = state.copyWith(highlighterWidth: width);

  void setStrokeWidth(double width) =>
      state = state.copyWith(strokeWidth: width);

  // ============================================================
  // نمو الصفحة (Canvas growth)
  //
  // When the pen gets near an edge, the canvas gets bigger:
  //  - right / bottom: the canvas is just bigger, nothing moves.
  //  - left / top: new space is added BEFORE the content, so everything is
  //    moved right / down by the added amount (coordinates never go
  //    negative). The point the caller is using must be moved too.
  // ============================================================

  /// Call it with the pointer position while drawing.
  /// Returns the SAME visual point in the new coordinates (moved if the
  /// left or top edge grew). Use the returned point for the stroke.
  Offset checkAndExpandCanvas(Offset point) {
    if (!_expandingTools.contains(state.currentTool)) return point;

    // A point is a rectangle with no size.
    return point + _expandIfNearEdge(Rect.fromPoints(point, point));
  }

  /// Call it after the selection was moved or resized.
  /// Returns how much the content moved (zero if the canvas did not grow
  /// on the left or top).
  Offset checkAndExpandForSelection() {
    final bounds = _selectionBounds();
    if (bounds == null) return Offset.zero;

    return _expandIfNearEdge(bounds);
  }

  /// Shared by the two methods above: [area] is a point or a selection box.
  Offset _expandIfNearEdge(Rect area) {
    final size = state.canvasSize;

    final near = <_Edge>{
      if (area.left <= _expansionThreshold) _Edge.left,
      if (area.top <= _expansionThreshold) _Edge.top,
      if (area.right >= size.width - _expansionThreshold) _Edge.right,
      if (area.bottom >= size.height - _expansionThreshold) _Edge.bottom,
    };

    // An edge we moved away from can grow again.
    _spentEdges.retainAll(near);

    final toGrow = near.difference(_spentEdges);
    if (toGrow.isEmpty) return Offset.zero;

    return _growCanvas(toGrow);
  }

  /// Makes the canvas bigger on [edges]. Returns how much the content moved.
  Offset _growCanvas(Set<_Edge> edges) {
    double amount(_Edge edge) => edges.contains(edge) ? _expansionAmount : 0;

    final left = amount(_Edge.left);
    final top = amount(_Edge.top);
    final right = amount(_Edge.right);
    final bottom = amount(_Edge.bottom);

    final shift = Offset(left, top);
    final contentMoves = shift != Offset.zero;
    final size = state.canvasSize;

    // Growing right / bottom moves nothing, so nothing is rebuilt or saved.
    final blocks = contentMoves
        ? [for (final b in state.blocks) _shiftBlock(b, left, top)]
        : state.blocks;
    final strokes = contentMoves
        ? [for (final s in state.strokes) _shiftStroke(s, left, top)]
        : state.strokes;

    // One state update, so the screen only sees the final result.
    state = state.copyWith(
      canvasSize: Size(size.width + left + right, size.height + top + bottom),
      canvasExpansionShift: shift,
      canvasExpansionVersion: state.canvasExpansionVersion + 1,
      strokes: strokes,
      blocks: blocks,
    );

    _spentEdges
      ..clear()
      ..addAll(edges);

    if (contentMoves && blocks.isNotEmpty) {
      // Not awaited on purpose: the pointer events must not wait for saving.
      unawaited(_saveBlocks(blocks));
    }

    return shift;
  }

  void _resetExpansion() => _spentEdges.clear();

  // ============================================================
  // محاية
  void setEraserSize(double size) {
    state = state.copyWith(eraserSize: size);
  }

  void startErase(Offset point, {double eraserRadius = 14}) {
    _saveHistory();
    eraseAt(point, eraserRadius: eraserRadius);
  }

  void eraseAt(Offset point, {double eraserRadius = 14}) {
    final updated = StrokeEraser.eraseFromStrokes(
      strokes: state.strokes,
      erasePoint: point,
      radius: eraserRadius,
    );

    if (_sameStrokeList(updated, state.strokes)) return;
    state = state.copyWith(strokes: updated);
  }

  bool _sameStrokeList(List<Stroke> a, List<Stroke> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  // ============================================================
  // ألوان وأدوات
  void setColor(Color color) {
    final selectedText = state.selectedTextBlock;
    if (selectedText != null) {
      _replaceBlockAndPersist(
          _rebuildText(selectedText, colorValue: color.value));
      return;
    }

    switch (state.currentTool) {
      case CanvasTool.highlighter:
        state = state.copyWith(highlighterColor: color);
      case CanvasTool.magic:
        state =
            state.copyWith(currentColor: color, currentTool: CanvasTool.magic);
      case CanvasTool.lasso:
        state =
            state.copyWith(currentColor: color, currentTool: CanvasTool.lasso);
      default:
        state =
            state.copyWith(currentColor: color, currentTool: CanvasTool.pen);
    }
  }

  void setTool(CanvasTool tool) {
    final keepSelection = tool == CanvasTool.lasso || tool == CanvasTool.pan;
    state = state.copyWith(
      currentTool: tool,
      clearSelectedBlockIds: !keepSelection,
      clearSelectedStrokeIds: !keepSelection,
      clearMarqueeRect: !keepSelection,
    );
    _marqueeStart = null;
    _lastDragPoint = null;
    _isDraggingSelection = false;
  }

  // ============================================================
  // تحديد: بلوكات محفوظة + strokes حيّة
  void selectAt(Offset point) {
    _dragMoved = false;
    _dragSnapshotTaken = false;
    _resetExpansion(); // every new touch starts fresh

    final bounds = state.hasSelection ? _selectionBounds() : null;
    if (bounds != null && bounds.inflate(6).contains(point)) {
      _isDraggingSelection = true;
      _lastDragPoint = point;
      _marqueeStart = null;
      return;
    }

    ContentBlock? hit;
    // for (final block in state.blocks.reversed) {
    //   if (block is TextBlock) {
    //     final availableWidth =
    //         (state.canvasSize.width - block.x).clamp(0.0, double.infinity);

    //     final textRect = CanvasGeometry.blockRect(
    //       block,
    //       maxWidth: availableWidth,
    //     );

    //     if (textRect.contains(point)) {
    //       hit = block;
    //       break;
    //     }
    //   }
    // }
    for (final block in state.blocks.reversed) {
      if (block is TextBlock &&
          TextBlockLayout.boundsOf(block, canvasRight: state.canvasSize.width)
              .contains(point)) {
        hit = block;
        break;
      }
    }

    if (hit != null) {
      state = state.copyWith(
        selectedBlockIds: {hit.id},
        clearSelectedStrokeIds: true,
        clearMarqueeRect: true,
      );
      _isDraggingSelection = true;
      _lastDragPoint = point;
      _marqueeStart = null;
      return;
    }

    for (final block in state.blocks.reversed) {
      if (block is! InkBlock) continue;
      for (final stroke in block.strokes.reversed) {
        if (!CanvasGeometry.strokeIntersectsRect(
          stroke,
          Rect.fromCircle(center: point, radius: 8),
        )) {
          continue;
        }

        state = state.copyWith(
          selectedStrokeIds: {stroke.id},
          clearSelectedBlockIds: true,
          clearMarqueeRect: true,
        );
        _isDraggingSelection = true;
        _lastDragPoint = point;
        _marqueeStart = null;
        return;
      }
    }

    _isDraggingSelection = false;
    _marqueeStart = point;
    _lastDragPoint = null;
    state = state.copyWith(
      clearSelectedBlockIds: true,
      clearSelectedStrokeIds: true,
      marqueeRect: Rect.fromPoints(point, point),
    );
  }

  void updateSelection(Offset point) {
    if (_isDraggingSelection) {
      _dragSelection(point);
      return;
    }

    final start = _marqueeStart;
    if (start == null) return;
    final rect = Rect.fromPoints(start, point);

    state = state.copyWith(
      marqueeRect: rect,
      selectedStrokeIds: {
        for (final s in state.strokes)
          if (CanvasGeometry.strokeIntersectsRect(s, rect)) s.id,
        for (final block in state.blocks)
          if (block is InkBlock)
            for (final s in block.strokes)
              if (CanvasGeometry.strokeIntersectsRect(s, rect)) s.id,
      },
      selectedBlockIds: {
        for (final b in state.blocks)
          // if (b is TextBlock && rect.overlaps(CanvasGeometry.blockRect(b)))
          //   b.id,
          if (b is TextBlock &&
              rect.overlaps(TextBlockLayout.boundsOf(
                b,
                canvasRight: state.canvasSize.width,
              )))
            b.id,
      },
    );
  }

  Future<void> endSelection() async {
    if (_isDraggingSelection) {
      _isDraggingSelection = false;
      _lastDragPoint = null;
      _dragSnapshotTaken = false;
      if (_dragMoved) await _persistSelectedBlocks();
      _dragMoved = false;
      return;
    }
    _marqueeStart = null;
    state = state.copyWith(clearMarqueeRect: true);
  }

  /// One box around everything that is selected (null if nothing is).
  /// SelectionGeometry already looks inside the ink blocks, so it only needs
  /// the lists from the state.
  Rect? _selectionBounds() => SelectionGeometry.boundsOf(
        strokes: state.strokes,
        blocks: state.blocks,
        selectedBlockIds: state.selectedBlockIds,
        selectedStrokeIds: state.selectedStrokeIds,
        page: state.canvasSize,
      );

  void _dragSelection(Offset point) {
    final last = _lastDragPoint;
    if (last == null) return;

    final dx = point.dx - last.dx;
    final dy = point.dy - last.dy;
    if (dx == 0 && dy == 0) return;

    _lastDragPoint = point;
    _dragMoved = true;

    if (!_dragSnapshotTaken && state.selectedStrokeIds.isNotEmpty) {
      _saveHistory();
      _dragSnapshotTaken = true;
    }

    state = state.copyWith(
      blocks: [
        for (final b in state.blocks)
          if (b is InkBlock)
            _shiftSelectedInkBlock(b, dx, dy)
          else if (state.selectedBlockIds.contains(b.id))
            _shiftBlock(b, dx, dy)
          else
            b,
      ],
      strokes: [
        for (final s in state.strokes)
          state.selectedStrokeIds.contains(s.id) ? _shiftStroke(s, dx, dy) : s,
      ],
    );
    checkAndExpandForSelection();
  }

  // ---- moving things ------------------------------------------------------

  Stroke _shiftStroke(Stroke s, double dx, double dy) => s.copyWith(
        points: [
          for (final p in s.points) StrokePoint(x: p.x + dx, y: p.y + dy),
        ],
      );

  /// Moves a whole block (used when the canvas grows on the left / top).
  ContentBlock _shiftBlock(ContentBlock block, double dx, double dy) {
    if (block is InkBlock) {
      return block.copyWith(
        x: block.x + dx,
        y: block.y + dy,
        strokes: [for (final s in block.strokes) _shiftStroke(s, dx, dy)],
      );
    }
    if (block is TextBlock) {
      return _rebuildText(block, x: block.x + dx, y: block.y + dy);
    }
    if (block is ImageBlock) {
      return block.copyWith(x: block.x + dx, y: block.y + dy);
    }
    return block;
  }

  /// Moves only the SELECTED strokes inside an ink block.
  InkBlock _shiftSelectedInkBlock(InkBlock block, double dx, double dy) {
    final selectedIds = state.selectedStrokeIds;
    if (!block.strokes.any((s) => selectedIds.contains(s.id))) return block;

    return block.copyWith(
      strokes: [
        for (final stroke in block.strokes)
          selectedIds.contains(stroke.id)
              ? _shiftStroke(stroke, dx, dy)
              : stroke,
      ],
      updatedAt: DateTime.now(),
    );
  }

  //_______________________________________
//Resize handles:
  void beginResize() {
    _resetExpansion();
    final bounds = _selectionBounds();
    if (bounds == null) return;

    _resizeStartStrokes = state.strokes;
    _resizeStartBlocks = state.blocks;
    _resizeStartBounds = bounds;
    _resizeSnapshotTaken = false;
    _resizeMoved = false;
  }

  /// Finger moved.
  /// [delta] = TOTAL movement since beginResize(), in scene units
  /// (SelectionBoundingBox already converts screen pixels to scene units).
  ///
  /// Every call starts again from the snapshot, so there is no drift.
  void resizeSelection(
    Offset delta,
    ResizeHandlePosition handle, {
    bool keepAspectRatio = true,
  }) {
    final startBounds = _resizeStartBounds;
    final startStrokes = _resizeStartStrokes;
    final startBlocks = _resizeStartBlocks;
    if (startBounds == null || startStrokes == null || startBlocks == null) {
      return;
    }

    final hasText = SelectionGeometry.containsText(
      blocks: startBlocks,
      selectedBlockIds: state.selectedBlockIds,
    );

    final transform = computeResizeTransform(
      startRect: startBounds,
      handle: handle,
      delta: delta,
      keepAspectRatio: keepAspectRatio || hasText, // text is always uniform
      minSize: 10,
    );

    // Same pattern as _dragSnapshotTaken: ONE undo step for the whole drag,
    // and none if the user only touched the handle.
    if (!_resizeSnapshotTaken && !transform.isIdentity) {
      _saveHistory();
      _resizeSnapshotTaken = true;
    }
    if (!transform.isIdentity) _resizeMoved = true;

    final strokeIds = state.selectedStrokeIds;
    final blockIds = state.selectedBlockIds;

    state = state.copyWith(
      strokes: [
        for (final s in startStrokes)
          strokeIds.contains(s.id) ? _scaleStroke(s, transform) : s,
      ],
      blocks: [
        for (final b in startBlocks)
          _scaleBlock(b, transform, blockIds, strokeIds),
      ],
    );

    // If the canvas grew on the left / top, the snapshot we start from must
    // move with it, or the next frame would put the content back.
    final expansion = checkAndExpandForSelection();
    if (expansion != Offset.zero) {
      _resizeStartStrokes = [
        for (final stroke in startStrokes)
          _shiftStroke(stroke, expansion.dx, expansion.dy),
      ];
      _resizeStartBlocks = [
        for (final block in startBlocks)
          _shiftBlock(block, expansion.dx, expansion.dy),
      ];
      _resizeStartBounds = startBounds.shift(expansion);
    }
  }

  /// Finger lifted. Saves the changed blocks, like endSelection() does.
  Future<void> endResize() async {
    final moved = _resizeMoved;

    _resizeStartStrokes = null;
    _resizeStartBlocks = null;
    _resizeStartBounds = null;
    _resizeSnapshotTaken = false;
    _resizeMoved = false;

    if (moved) await _persistSelectedBlocks();
  }

  StrokePoint _scalePoint(StrokePoint p, ResizeTransform t) {
    final q = t.apply(Offset(p.x, p.y)); // a + (p - a) * scale
    return StrokePoint(x: q.dx, y: q.dy);
  }

  Stroke _scaleStroke(Stroke s, ResizeTransform t) => Stroke(
        id: s.id,
        points: [for (final p in s.points) _scalePoint(p, t)],
        colorValue: s.colorValue,
        // Corner drag: the line gets thicker / thinner with the drawing.
        // Edge drag (stretch): keep the thickness.
        strokeWidth: s.strokeWidth * (t.isUniform ? t.scaleX : 1.0),
        createdAt: s.createdAt,
      );

  ContentBlock _scaleBlock(
    ContentBlock block,
    ResizeTransform t,
    Set<String> selectedBlockIds,
    Set<String> selectedStrokeIds,
  ) {
    // Strokes that live inside a saved InkBlock (selected by stroke id).
    // Like _shiftSelectedInkBlock: the block's own x/y/width/height are not
    // touched, the painter takes the bounds from the strokes.
    if (block is InkBlock) {
      if (!block.strokes.any((s) => selectedStrokeIds.contains(s.id))) {
        return block;
      }
      return block.copyWith(
        strokes: [
          for (final s in block.strokes)
            selectedStrokeIds.contains(s.id) ? _scaleStroke(s, t) : s,
        ],
        updatedAt: DateTime.now(),
      );
    }

    if (block is TextBlock && selectedBlockIds.contains(block.id)) {
      final scale = t.scaleX; // text is always uniform: scaleX == scaleY
      final topLeft = t.apply(Offset(block.x, block.y));
      final fontSize = block.fontSize * scale;
      final width = (block.width > 0 ? block.width : _defaultTextWidth) * scale;

      return block.copyWith(
        x: topLeft.dx,
        y: topLeft.dy,
        fontSize: fontSize,
        width: width,
        height: measureTextHeight(
          text: block.text,
          fontFamily: block.fontFamily,
          fontSize: fontSize,
          width: width,
        ),
        updatedAt: DateTime.now(),
      );
    }

    return block;
  }

  //_______________________________________
  // Saving

  /// Saves [blocks] one by one. If some fail, the last failure is shown.
  Future<void> _saveBlocks(Iterable<ContentBlock> blocks) async {
    final saveBlock = ref.read(saveBlockUseCaseProvider);
    Failure? lastFailure;

    for (final block in blocks) {
      final result = await saveBlock(SaveBlockParams(block));
      result.fold((f) => lastFailure = f, (_) {});
    }

    if (lastFailure != null) state = state.copyWith(error: lastFailure);
  }

  /// Saves the selected text blocks and the ink blocks that contain
  /// selected strokes.
  Future<void> _persistSelectedBlocks() {
    final strokeIds = state.selectedStrokeIds;
    final blockIds = state.selectedBlockIds;

    return _saveBlocks([
      for (final block in state.blocks)
        if (blockIds.contains(block.id) ||
            (block is InkBlock &&
                block.strokes.any((s) => strokeIds.contains(s.id))))
          block,
    ]);
  }

  Future<void> _replaceBlockAndPersist(ContentBlock updated) async {
    state = state.copyWith(
      blocks: [for (final b in state.blocks) b.id == updated.id ? updated : b],
    );

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final result = await saveBlock(SaveBlockParams(updated));
    result.fold((f) => state = state.copyWith(error: f), (_) {});
  }

  // ============================================================
  // حذف
  // ============================================================

  Future<void> deleteSelection() async {
    final blockIds = state.selectedBlockIds;
    final deleted = <String>{};
    Failure? lastFailure;

    if (blockIds.isNotEmpty) {
      final deleteBlock = ref.read(deleteBlockUseCaseProvider);
      for (final id in blockIds) {
        final result = await deleteBlock(DeleteBlockParams(id));
        result.fold((f) => lastFailure = f, (_) => deleted.add(id));
      }
    }

    var remainingStrokes = state.strokes;
    if (state.selectedStrokeIds.isNotEmpty) {
      _saveHistory();
      remainingStrokes = state.strokes
          .where((s) => !state.selectedStrokeIds.contains(s.id))
          .toList();
    }

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final updatedBlocks = <ContentBlock>[];
    for (final block in state.blocks) {
      if (block is! InkBlock ||
          !block.strokes
              .any((stroke) => state.selectedStrokeIds.contains(stroke.id))) {
        updatedBlocks.add(block);
        continue;
      }

      final remainingBlockStrokes = block.strokes
          .where((stroke) => !state.selectedStrokeIds.contains(stroke.id))
          .toList();
      if (remainingBlockStrokes.isEmpty) {
        final result = await ref
            .read(deleteBlockUseCaseProvider)(DeleteBlockParams(block.id));
        result.fold((f) => lastFailure = f, (_) {});
        continue;
      }

      final updated = block.copyWith(strokes: remainingBlockStrokes);
      final result = await saveBlock(SaveBlockParams(updated));
      result.fold((f) {
        lastFailure = f;
        updatedBlocks.add(block);
      }, (_) => updatedBlocks.add(updated));
    }

    state = state.copyWith(
      blocks: updatedBlocks.where((b) => !deleted.contains(b.id)).toList(),
      strokes: remainingStrokes,
      selectedBlockIds: blockIds.difference(deleted),
      clearSelectedStrokeIds: true,
      error: lastFailure,
      clearError: lastFailure == null,
    );
  }

  // ============================================================
  // نص
  TextBlock _rebuildText(
    TextBlock block, {
    String? text,
    double? fontSize,
    int? colorValue,
    double? x,
    double? y,
  }) {
    final newText = text ?? block.text;
    final newFontSize = fontSize ?? block.fontSize;
    //   final width = block.width > 0 ? block.width : _defaultTextWidth;
    // Changing only the font size (the slider) scales the width too, so the
    // text keeps the same line breaks and just gets bigger or smaller.
    final oldWidth = block.width > 0 ? block.width : _defaultTextWidth;
    final width = (fontSize != null && block.fontSize > 0)
        ? oldWidth * fontSize / block.fontSize
        : oldWidth;

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

  Future<void> editSelectedText(String newText) async {
    final selected = state.selectedTextBlock;
    if (selected == null || newText.trim().isEmpty) return;
    await _replaceBlockAndPersist(_rebuildText(selected, text: newText));
  }

  void previewSelectedTextFontSize(double size) {
    final selected = state.selectedTextBlock;
    if (selected == null) return;

    final updated = _rebuildText(selected, fontSize: size);
    state = state.copyWith(
      blocks: [for (final b in state.blocks) b.id == updated.id ? updated : b],
    );
  }

  Future<void> commitSelectedTextFontSize() async {
    final selected = state.selectedTextBlock;
    if (selected == null) return;

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final result = await saveBlock(SaveBlockParams(selected));
    result.fold((f) => state = state.copyWith(error: f), (_) {});
  }

  // ============================================================
  // حفظ / مسح
  // ============================================================

  Future<void> saveCurrentDrawing() async {
    _resetHistory();

    if (state.strokes.isEmpty) {
      return;
    }

    final bounds = CanvasGeometry.strokesBounds(state.strokes);
    if (bounds == null) {
      return;
    }

    final now = DateTime.now();
    final block = InkBlock(
      id: now.millisecondsSinceEpoch.toString(),
      pageId: pageId,
      orderIndex: state.blocks.length,
      x: bounds.left,
      y: bounds.top,
      width: bounds.width,
      height: bounds.height,
      strokes: state.strokes,
      createdAt: now,
      updatedAt: now,
    );

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final result = await saveBlock(SaveBlockParams(block));

    state = result.fold(
      (failure) => state.copyWith(error: failure),
      (_) {
        return state.copyWith(
          blocks: [...state.blocks, block],
          strokes: [],
          clearSelectedStrokeIds: true,
          canUndo: false,
          canRedo: false,
        );
      },
    );
  }
  Future<void> saveOnExit() async {
    if (state.strokes.isEmpty || state.isRecognizing) return;

    // A pending "convert to text" refers to live strokes that are about to be
    // saved as ink, so drop it (otherwise confirming it later would add the
    // text AND leave the ink).
    if (state.pendingRecognizedText != null) discardRecognition();

    await saveCurrentDrawing();
  }

  Future<void> clear() async {
    _saveHistory();

    final deleteBlock = ref.read(deleteBlockUseCaseProvider);
    final remainingBlocks = <ContentBlock>[];
    Failure? lastFailure;

    for (final block in state.blocks) {
      final result = await deleteBlock(DeleteBlockParams(block.id));
      result.fold((f) {
        lastFailure = f;
        remainingBlocks.add(block);
      }, (_) {});
    }

    state = state.copyWith(
      strokes: [],
      blocks: remainingBlocks,
      error: lastFailure,
      clearError: lastFailure == null,
      clearPendingRecognition: true,
      clearSelectedStrokeIds: true,
      clearSelectedBlockIds: true,
      clearMarqueeRect: true,
    );
  }

  // ============================================================
  // التعرف على الكتابة
  // ============================================================

  Future<void> convertToText({required String language}) async {
    if (state.selectedStrokeIds.isEmpty) return;

    final strokesToConvert = state.strokes
        .where((s) => state.selectedStrokeIds.contains(s.id))
        .toList();
    if (strokesToConvert.isEmpty) return;

    state = state.copyWith(isRecognizing: true, clearError: true);

    final convertHandwriting = ref.read(convertHandwritingUseCaseProvider);
    final result = await convertHandwriting(
      ConvertHandwritingParams(strokes: strokesToConvert, language: language),
    );

    state = result.fold(
      (failure) => state.copyWith(isRecognizing: false, error: failure),
      (text) => state.copyWith(
        isRecognizing: false,
        pendingRecognizedText: text,
        pendingRecognitionBounds:
            CanvasGeometry.strokesBounds(strokesToConvert),
        pendingRecognitionStrokeIds: strokesToConvert.map((s) => s.id).toSet(),
      ),
    );
  }

  void updatePendingText(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(pendingRecognizedText: text);
  }

  Future<void> confirmRecognition() async {
    final bounds = state.pendingRecognitionBounds;
    final text = state.pendingRecognizedText;
    final convertedIds = state.pendingRecognitionStrokeIds;
    if (bounds == null || text == null) return;

    final now = DateTime.now();
    final width = bounds.width < 160 ? 160.0 : bounds.width;

    final block = TextBlock(
      id: now.millisecondsSinceEpoch.toString(),
      pageId: pageId,
      orderIndex: state.blocks.length,
      x: bounds.left,
      y: bounds.top,
      width: width,
      height: measureTextHeight(
        text: text,
        fontFamily: _defaultFont,
        fontSize: _defaultFontSize,
        width: width,
      ),
      text: text,
      fontFamily: _defaultFont,
      colorValue: state.currentColor.value,
      fontSize: _defaultFontSize,
      createdAt: now,
      updatedAt: now,
    );

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final result = await saveBlock(SaveBlockParams(block));

    state = result.fold(
      (failure) => state.copyWith(error: failure),
      (_) => state.copyWith(
        blocks: [...state.blocks, block],
        strokes:
            state.strokes.where((s) => !convertedIds.contains(s.id)).toList(),
        clearSelectedStrokeIds: true,
        clearPendingRecognition: true,
      ),
    );
  }

  void discardRecognition() {
    state = state.copyWith(
        clearPendingRecognition: true, clearSelectedStrokeIds: true);
  }

  // ============================================================
  // إضافة نص
  // ============================================================

  Future<void> addTextBlock(String text, Offset position) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final block = TextBlock(
      id: now.millisecondsSinceEpoch.toString(),
      pageId: pageId,
      orderIndex: state.blocks.length,
      x: position.dx,
      y: position.dy,
      width: _defaultTextWidth,
      height: measureTextHeight(
        text: text,
        fontFamily: _defaultFont,
        fontSize: _defaultFontSize,
        width: _defaultTextWidth,
      ),
      text: text,
      fontFamily: _defaultFont,
      colorValue: state.currentColor.value,
      fontSize: _defaultFontSize,
      createdAt: now,
      updatedAt: now,
    );

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final result = await saveBlock(SaveBlockParams(block));

    state = result.fold(
      (failure) => state.copyWith(error: failure),
      (_) => state.copyWith(
        blocks: [...state.blocks, block],
        clearError: true,
        selectedBlockIds: {block.id},
        clearSelectedStrokeIds: true,
        currentTool: CanvasTool.lasso,
      ),
    );
  }

  void dismissError() => state = state.copyWith(clearError: true);
}
