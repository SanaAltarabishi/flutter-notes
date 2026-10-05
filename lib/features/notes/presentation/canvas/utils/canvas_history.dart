import '../../../domain/entities/stroke.dart';
import '../../../domain/entities/content_block.dart';

class CanvasHistorySnapshot {
  final List<Stroke> strokes;
  final List<ContentBlock> blocks;

  const CanvasHistorySnapshot({
    required this.strokes,
    required this.blocks,
  });
}

class CanvasHistory {
  final List<CanvasHistorySnapshot> _undoStack = [];
  final List<CanvasHistorySnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void save(
      {required List<Stroke> strokes, required List<ContentBlock> blocks}) {
    _undoStack.add(CanvasHistorySnapshot(
      strokes: List<Stroke>.of(strokes),
      blocks: List<ContentBlock>.of(blocks),
    ));
    _redoStack.clear();
  }

  CanvasHistorySnapshot? undo({
    required List<Stroke> currentStrokes,
    required List<ContentBlock> currentBlocks,
  }) {
    if (_undoStack.isEmpty) return null;

    _redoStack.add(CanvasHistorySnapshot(
      strokes: List<Stroke>.of(currentStrokes),
      blocks: List<ContentBlock>.of(currentBlocks),
    ));
    return _undoStack.removeLast();
  }

  CanvasHistorySnapshot? redo({
    required List<Stroke> currentStrokes,
    required List<ContentBlock> currentBlocks,
  }) {
    if (_redoStack.isEmpty) return null;

    _undoStack.add(CanvasHistorySnapshot(
      strokes: List<Stroke>.of(currentStrokes),
      blocks: List<ContentBlock>.of(currentBlocks),
    ));
    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
