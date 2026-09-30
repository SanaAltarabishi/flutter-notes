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
import 'utils/stroke_eraser.dart';

final canvasProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, String>(
  CanvasNotifier.new,
);

class CanvasNotifier extends FamilyNotifier<CanvasState, String> {
  late final String pageId;
  static const double _defaultTextWidth = 220;
  static const double _defaultFontSize = 18;
  static const String _defaultFont = 'Roboto';

  final CanvasHistory _history = CanvasHistory(); //todo :

  Offset? _lastDragPoint;
  Offset? _marqueeStart;
  bool _isDraggingSelection = false;
  bool _dragMoved = false;
  bool _dragSnapshotTaken = false;
//_______________________________________________
  @override
  CanvasState build(String arg) {
    pageId = arg;

    _loadBlocks();

    return const CanvasState();
  }

//_______________________________________________
  Future<void> _loadBlocks() async {
    final getBlocks = ref.read(getBlocksUseCaseProvider);

    final result = await getBlocks(
      GetBlocksParams(pageId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure,
        );
      },
      (blocks) {
        state = state.copyWith(
          blocks: blocks,
          clearError: true,
        );
      },
    );
  }

//_______________________________________________
  void setCanvasSize(Size size) {
    state = state.copyWith(
      canvasSize: size,
    );
  }

//_______________________________________________
//undo\ redo :
  void _saveHistory() {
    _history.save(state.strokes);

    state = state.copyWith(
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

  void undo() {
    final previous = _history.undo(state.strokes);

    if (previous == null) return;

    state = state.copyWith(
      strokes: previous,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

  void redo() {
    final next = _history.redo(state.strokes);

    if (next == null) return;

    state = state.copyWith(
      strokes: next,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

//_______________________________________________
//drawing :
  void startStroke(Offset point) {
    _saveHistory();

    final isHighlighter = state.currentTool == CanvasTool.highlighter;

    final baseColor =
        isHighlighter ? state.highlighterColor : state.currentColor;

    final color = isHighlighter ? baseColor.withOpacity(0.35) : baseColor;

    final width = isHighlighter ? state.highlighterWidth : state.strokeWidth;

    final now = DateTime.now();

    final newStroke = Stroke(
      id: now.millisecondsSinceEpoch.toString(),
      points: [
        StrokePoint(
          x: point.dx,
          y: point.dy,
        ),
      ],
      colorValue: color.value,
      strokeWidth: width,
      createdAt: now,
    );

    state = state.copyWith(
      strokes: [
        ...state.strokes,
        newStroke,
      ],
    );
  }

//--------------------------
  void addPoint(Offset point) {
    if (state.strokes.isEmpty) return;

    final lastStroke = state.strokes.last;

    final updatedStroke = lastStroke.copyWith(
      points: [
        ...lastStroke.points,
        StrokePoint(
          x: point.dx,
          y: point.dy,
        ),
      ],
    );

    final updatedStrokes = [
      ...state.strokes,
    ];

    updatedStrokes[updatedStrokes.length - 1] = updatedStroke;

    state = state.copyWith(
      strokes: updatedStrokes,
    );
  }

  void endStroke() {}
//_______________________________________________
//strok settings ;
  void setHighlighterWidth(double width) {
    state = state.copyWith(
      highlighterWidth: width,
    );
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(
      strokeWidth: width,
    );
  }

//_______________________________________________
//earser :
  void startErase(Offset point) {
    _saveHistory();

    eraseAt(point);
  }

  void eraseAt(
    Offset point, {
    double eraserRadius = 14,
  }) {
    final updatedStrokes = StrokeEraser.eraseFromStrokes(
      strokes: state.strokes,
      erasePoint: point,
      radius: eraserRadius,
    );

    if (_sameStrokeList(updatedStrokes, state.strokes)) {
      return;
    }

    state = state.copyWith(
      strokes: updatedStrokes,
    );
  }

  bool _sameStrokeList(
    List<Stroke> first,
    List<Stroke> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var i = 0; i < first.length; i++) {
      if (!identical(first[i], second[i])) {
        return false;
      }
    }

    return true;
  }

//_______________________________________________
//tools/colors :
  void setColor(Color color) {
    final selectedText = state.selectedTextBlock;

    if (selectedText != null) {
      _replaceBlockAndPersist(
        _rebuildText(
          selectedText,
          colorValue: color.value,
        ),
      );

      return;
    }

    if (state.currentTool == CanvasTool.highlighter) {
      state = state.copyWith(
        highlighterColor: color,
        currentTool: CanvasTool.highlighter,
      );
    } else if (state.currentTool == CanvasTool.magic) {
      state = state.copyWith(
        currentColor: color,
        currentTool: CanvasTool.magic,
      );
    } else {
      state = state.copyWith(
        currentColor: color,
        currentTool: CanvasTool.pen,
      );
    }
  }

  void setTool(CanvasTool tool) {
    final keepSelection = tool == CanvasTool.lasso;

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

//_______________________________________________
//selection :
  void selectAt(Offset point) {
    _dragMoved = false;
    _dragSnapshotTaken = false;

    final hasSelection = state.hasSelection;

    final bounds = hasSelection ? _selectionBounds() : null;

    if (bounds != null && bounds.inflate(6).contains(point)) {
      _isDraggingSelection = true;
      _lastDragPoint = point;
      _marqueeStart = null;

      return;
    }

    ContentBlock? hit;

    for (final block in state.blocks.reversed) {
      if (CanvasGeometry.blockRect(block).contains(point)) {
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

    _isDraggingSelection = false;
    _marqueeStart = point;
    _lastDragPoint = null;

    state = state.copyWith(
      clearSelectedBlockIds: true,
      clearSelectedStrokeIds: true,
      marqueeRect: Rect.fromPoints(
        point,
        point,
      ),
    );
  }

  void updateSelection(Offset point) {
    if (_isDraggingSelection) {
      _dragSelection(point);
      return;
    }

    final start = _marqueeStart;

    if (start == null) return;

    final rect = Rect.fromPoints(
      start,
      point,
    );

    final strokeIds = <String>{};

    for (final stroke in state.strokes) {
      final isInside = stroke.points.any(
        (p) => rect.contains(
          Offset(p.x, p.y),
        ),
      );

      if (isInside) {
        strokeIds.add(stroke.id);
      }
    }

    final blockIds = <String>{};

    for (final block in state.blocks) {
      if (rect.overlaps(
        CanvasGeometry.blockRect(block),
      )) {
        blockIds.add(block.id);
      }
    }

    state = state.copyWith(
      marqueeRect: rect,
      selectedStrokeIds: strokeIds,
      selectedBlockIds: blockIds,
    );
  }

  Future<void> endSelection() async {
    if (_isDraggingSelection) {
      _isDraggingSelection = false;
      _lastDragPoint = null;
      _dragSnapshotTaken = false;

      if (_dragMoved) {
        await _persistSelectedBlocks();
      }

      _dragMoved = false;

      return;
    }

    _marqueeStart = null;

    state = state.copyWith(
      clearMarqueeRect: true,
    );
  }

  Rect? _selectionBounds() {
    return CanvasGeometry.selectionBounds(
      blocks: state.blocks,
      strokes: state.strokes,
      selectedBlockIds: state.selectedBlockIds,
      selectedStrokeIds: state.selectedStrokeIds,
    );
  }

//_______________________________________________
//drag :
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

    final movedBlocks = [
      for (final block in state.blocks)
        state.selectedBlockIds.contains(block.id)
            ? _shiftBlock(block, dx, dy)
            : block,
    ];

    final movedStrokes = state.strokes.map(
      (stroke) {
        if (!state.selectedStrokeIds.contains(stroke.id)) {
          return stroke;
        }

        return _shiftStroke(
          stroke,
          dx,
          dy,
        );
      },
    ).toList();

    state = state.copyWith(
      blocks: movedBlocks,
      strokes: movedStrokes,
    );
  }

  Stroke _shiftStroke(
    Stroke stroke,
    double dx,
    double dy,
  ) {
    return Stroke(
      id: stroke.id,
      points: stroke.points
          .map(
            (point) => StrokePoint(
              x: point.x + dx,
              y: point.y + dy,
            ),
          )
          .toList(),
      colorValue: stroke.colorValue,
      strokeWidth: stroke.strokeWidth,
      createdAt: stroke.createdAt,
    );
  }

  ContentBlock _shiftBlock(
    ContentBlock block,
    double dx,
    double dy,
  ) {
    if (block is InkBlock) {
      return InkBlock(
        id: block.id,
        pageId: block.pageId,
        orderIndex: block.orderIndex,
        x: block.x + dx,
        y: block.y + dy,
        width: block.width,
        height: block.height,
        strokes: block.strokes
            .map(
              (stroke) => _shiftStroke(
                stroke,
                dx,
                dy,
              ),
            )
            .toList(),
        recognizedText: block.recognizedText,
        createdAt: block.createdAt,
        updatedAt: block.updatedAt,
      );
    }

    if (block is TextBlock) {
      return _rebuildText(
        block,
        x: block.x + dx,
        y: block.y + dy,
      );
    }

    return block;
  }

//_______________________________________________
//persist changes to selected blocks :
  Future<void> _persistSelectedBlocks() async {
    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

    Failure? lastFailure;

    for (final block in state.blocks) {
      if (!state.selectedBlockIds.contains(block.id)) {
        continue;
      }

      final result = await saveBlock(
        SaveBlockParams(block),
      );

      result.fold(
        (failure) => lastFailure = failure,
        (_) {},
      );
    }

    if (lastFailure != null) {
      state = state.copyWith(
        error: lastFailure,
      );
    }
  }

  Future<void> _replaceBlockAndPersist(
    ContentBlock updated,
  ) async {
    state = state.copyWith(
      blocks: [
        for (final block in state.blocks)
          block.id == updated.id ? updated : block,
      ],
    );

    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

    final result = await saveBlock(
      SaveBlockParams(updated),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure,
        );
      },
      (_) {},
    );
  }

//_______________________________________________
//delete :
  Future<void> deleteSelection() async {
    final blockIds = state.selectedBlockIds;

    final deleted = <String>{};

    Failure? lastFailure;

    if (blockIds.isNotEmpty) {
      final deleteBlock = ref.read(
        deleteBlockUseCaseProvider,
      );

      for (final id in blockIds) {
        final result = await deleteBlock(
          DeleteBlockParams(id),
        );

        result.fold(
          (failure) => lastFailure = failure,
          (_) => deleted.add(id),
        );
      }
    }

    var remainingStrokes = state.strokes;

    if (state.selectedStrokeIds.isNotEmpty) {
      _saveHistory();

      remainingStrokes = state.strokes
          .where(
            (stroke) => !state.selectedStrokeIds.contains(
              stroke.id,
            ),
          )
          .toList();
    }

    state = state.copyWith(
      blocks: state.blocks
          .where(
            (block) => !deleted.contains(block.id),
          )
          .toList(),
      strokes: remainingStrokes,
      selectedBlockIds: blockIds.difference(deleted),
      clearSelectedStrokeIds: true,
      error: lastFailure,
      clearError: lastFailure == null,
    );
  }

  //_______________________________________________
//text:
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

    final width = block.width > 0 ? block.width : _defaultTextWidth;

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

  Future<void> editSelectedText(
    String newText,
  ) async {
    final selected = state.selectedTextBlock;

    if (selected == null || newText.trim().isEmpty) {
      return;
    }

    await _replaceBlockAndPersist(
      _rebuildText(
        selected,
        text: newText,
      ),
    );
  }

  void previewSelectedTextFontSize(
    double size,
  ) {
    final selected = state.selectedTextBlock;

    if (selected == null) return;

    final updated = _rebuildText(
      selected,
      fontSize: size,
    );

    state = state.copyWith(
      blocks: [
        for (final block in state.blocks)
          block.id == updated.id ? updated : block,
      ],
    );
  }

  Future<void> commitSelectedTextFontSize() async {
    final selected = state.selectedTextBlock;

    if (selected == null) return;

    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

    final result = await saveBlock(
      SaveBlockParams(selected),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure,
        );
      },
      (_) {},
    );
  }

//_______________________________________________
//save:
  Future<void> saveCurrentDrawing() async {
    if (state.strokes.isEmpty) return;

    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

    final now = DateTime.now();

    final bounds = CanvasGeometry.strokesBounds(
      state.strokes,
    );

    if (bounds == null) return;

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

    final result = await saveBlock(
      SaveBlockParams(block),
    );

    state = result.fold(
      (failure) {
        return state.copyWith(
          error: failure,
        );
      },
      (_) {
        return state.copyWith(
          blocks: [
            ...state.blocks,
            block,
          ],
          strokes: [],
          clearSelectedStrokeIds: true,
        );
      },
    );
  }

//_______________________________________________
//clear:
  Future<void> clear() async {
    _saveHistory();

    final deleteBlock = ref.read(
      deleteBlockUseCaseProvider,
    );

    final remainingBlocks = <ContentBlock>[];

    Failure? lastFailure;

    for (final block in state.blocks) {
      final result = await deleteBlock(
        DeleteBlockParams(block.id),
      );

      result.fold(
        (failure) {
          lastFailure = failure;
          remainingBlocks.add(block);
        },
        (_) {},
      );
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

  //_______________________________________________
  // Handwriting recognition

  Future<void> convertToText({
    required String language,
  }) async {
    if (state.selectedStrokeIds.isEmpty) {
      return;
    }

    final strokesToConvert = state.strokes
        .where(
          (stroke) => state.selectedStrokeIds.contains(
            stroke.id,
          ),
        )
        .toList();

    if (strokesToConvert.isEmpty) {
      return;
    }

    state = state.copyWith(
      isRecognizing: true,
      clearError: true,
    );

    final convertHandwriting = ref.read(
      convertHandwritingUseCaseProvider,
    );

    final result = await convertHandwriting(
      ConvertHandwritingParams(
        strokes: strokesToConvert,
        language: language,
      ),
    );

    state = result.fold(
      (failure) {
        return state.copyWith(
          isRecognizing: false,
          error: failure,
        );
      },
      (text) {
        return state.copyWith(
          isRecognizing: false,
          pendingRecognizedText: text,
          pendingRecognitionBounds: CanvasGeometry.strokesBounds(
            strokesToConvert,
          ),
          pendingRecognitionStrokeIds:
              strokesToConvert.map((stroke) => stroke.id).toSet(),
        );
      },
    );
  }

  void updatePendingText(String text) {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      pendingRecognizedText: text,
    );
  }

  Future<void> confirmRecognition() async {
    final bounds = state.pendingRecognitionBounds;

    final text = state.pendingRecognizedText;

    final convertedIds = state.pendingRecognitionStrokeIds;

    if (bounds == null || text == null) {
      return;
    }

    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

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

    final result = await saveBlock(
      SaveBlockParams(block),
    );

    state = result.fold(
      (failure) {
        return state.copyWith(
          error: failure,
        );
      },
      (_) {
        return state.copyWith(
          blocks: [
            ...state.blocks,
            block,
          ],
          strokes: state.strokes
              .where(
                (stroke) => !convertedIds.contains(stroke.id),
              )
              .toList(),
          clearSelectedStrokeIds: true,
          clearPendingRecognition: true,
        );
      },
    );
  }

  void discardRecognition() {
    state = state.copyWith(
      clearPendingRecognition: true,
      clearSelectedStrokeIds: true,
    );
  }

  //_______________________________________________
  // Add text

  Future<void> addTextBlock(
    String text,
    Offset position,
  ) async {
    if (text.trim().isEmpty) return;

    final saveBlock = ref.read(
      saveBlockUseCaseProvider,
    );

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

    final result = await saveBlock(
      SaveBlockParams(block),
    );

    state = result.fold(
      (failure) {
        return state.copyWith(
          error: failure,
        );
      },
      (_) {
        return state.copyWith(
          blocks: [
            ...state.blocks,
            block,
          ],
          clearError: true,
          selectedBlockIds: {block.id},
          clearSelectedStrokeIds: true,
          currentTool: CanvasTool.lasso,
        );
      },
    );
  }
//_______________________________________________
  // Error

  void dismissError() {
    state = state.copyWith(
      clearError: true,
    );
  }
}
