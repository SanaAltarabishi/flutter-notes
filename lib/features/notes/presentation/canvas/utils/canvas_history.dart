import '../../../domain/entities/stroke.dart';

//handle redo\undo stroks:
class CanvasHistory {
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void save(List<Stroke> strokes) {
    //todo : why we use this
    _undoStack.add(List<Stroke>.of(strokes));
    _redoStack.clear();
  }

  List<Stroke>? undo(List<Stroke> currentStrokes) {
    if (_undoStack.isEmpty) return null;

    _redoStack.add(List<Stroke>.of(currentStrokes));
    return _undoStack.removeLast();
  }

  List<Stroke>? redo(List<Stroke> currentStrokes) {
    if (_redoStack.isEmpty) return null;

    _undoStack.add(List<Stroke>.of(currentStrokes));
    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
