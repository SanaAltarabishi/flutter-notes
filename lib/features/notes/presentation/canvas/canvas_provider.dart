import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/usecases/blocks/get_blocks.dart';
import '../../domain/usecases/blocks/save_block.dart';
import '../../domain/usecases/handwriting/convert_handwriting.dart';
import 'canvas_state.dart';
import '../providers/core_providers.dart';
/*
the differnt between them :
we have tow considers to take :
1. sync or async
2. with arg(single) or without arg (family)
> sync + without arg : NotifierProvider<NotifierClass, StateClass>
> sync + with arg : NotifierProvider.family<NotifierClass, StateClass, ArgType>
> async + without arg : AsyncNotifierProvider<NotifierClass, StateClass>
> async + with arg : AsyncNotifierProvider.family<NotifierClass, StateClass, ArgType
 */


final canvasProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, String>(
        CanvasNotifier.new);

class CanvasNotifier extends FamilyNotifier<CanvasState, String> {
  late final String pageId;
//___________________________________________________
  @override
  CanvasState build(String arg) {
    pageId = arg;
    _loadBlocks(); //without "await" because we don't want to wait for the result of _loadBlocks() before returning the initial state. We want to return the initial state immediately, and then load the blocks in the background.
    //it called :"fire-and-forget" meaning: we run it , but don't wait and complete
    return const CanvasState();
  }

//___________________________________________________
  Future<void> _loadBlocks() async {
    final getBlocks = ref.read(getBlocksUseCaseProvider);
    final result = await getBlocks(GetBlocksParams(pageId));
    result.fold(
      (failure) => state = state.copyWith(error: failure), //soft error
      (blocks) => state = state.copyWith(blocks: blocks, clearError: true),
    );
  }
//___________________________________________________
  void setCanvasSize(Size size) {
    state = state.copyWith(canvasSize: size);
  }
//__________________________________________________
  void startStroke(Offset point) {
    final newStroke = Stroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: [point],
      color: state.currentColor,
      strokeWidth: state.strokeWidth,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      strokes: [...state.strokes, newStroke],
      redoStack: [],
    );
  }
//___________________________________________________
  void addPoint(Offset point) {
    if (state.strokes.isEmpty) return;
    final lastStroke = state.strokes.last;
    final updatedStroke = lastStroke.copyWith(
      points: [...lastStroke.points, point],
    );
    final updatedStrokes = [...state.strokes];
    updatedStrokes[updatedStrokes.length - 1] = updatedStroke;
    state = state.copyWith(strokes: updatedStrokes);
  }
//___________________________________________________

  void endStroke() {
    // Stroke already added in startStroke
  }
//___________________________________________________

  void setColor(Color color) {
    state = state.copyWith(currentColor: color, currentTool: CanvasTool.pen);
  }
//___________________________________________________

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }
//___________________________________________________

  void setTool(CanvasTool tool) {
    state = state.copyWith(currentTool: tool);
  }
//___________________________________________________

  void undo() {
    if (state.strokes.isEmpty) return;
    final lastStroke = state.strokes.last;
    final updatedStrokes = state.strokes.sublist(0, state.strokes.length - 1);
    state = state.copyWith(
      strokes: updatedStrokes,
      redoStack: [...state.redoStack, lastStroke],
    );
  }
//___________________________________________________

  void redo() {
    if (state.redoStack.isEmpty) return;
    final lastRedo = state.redoStack.last;
    final updatedRedo = state.redoStack.sublist(0, state.redoStack.length - 1);
    state = state.copyWith(
      strokes: [...state.strokes, lastRedo],
      redoStack: updatedRedo,
    );
  }
//___________________________________________________

  void clear() {
    state = state.copyWith(
      strokes: [],
      redoStack: [],
      recognizedText: null,
      // error: null,
      clearError: true,
    );
  }
//___________________________________________________

  Future<void> convertToText({required String language}) async {
    if (state.strokes.isEmpty) return;

    state = state.copyWith(
        isRecognizing: true, clearError: true, recognizedText: null);

    final convertHandwriting = ref.read(convertHandwritingUseCaseProvider);
    final result = await convertHandwriting(
      ConvertHandwritingParams(
        strokes: state.strokes,
        language: language,
      ),
    );

    state = result.fold(
      (failure) => state.copyWith(isRecognizing: false, error: failure),
      (text) => state.copyWith(isRecognizing: false, recognizedText: text),
    );
  }

//___________________________________________________
  Future<void> saveRecognizedBlock() async {
    if (state.recognizedText == null || state.recognizedText!.isEmpty) return;

    final saveBlock = ref.read(saveBlockUseCaseProvider);
    final now = DateTime.now();

    final block = InkBlock(
      id: now.millisecondsSinceEpoch.toString(),
      pageId: pageId,
      orderIndex: state.blocks.length,
      strokes: state.strokes,
      recognizedText: state.recognizedText,
      createdAt: now,
      updatedAt: now,
    );

    final result = await saveBlock(SaveBlockParams(block));

    state = result.fold(
      (failure) => state.copyWith(error: failure),
      (_) => state.copyWith(
        blocks: [...state.blocks, block],
        recognizedText: null,
        strokes: [],
        redoStack: [],
        clearError: true,
      ),
    );
  }
//___________________________________________________

  void clearRecognizedText() {
    state = state.copyWith(recognizedText: null);
  }
//___________________________________________________

  void dismissError() {
    state = state.copyWith(clearError: true);
  }
}
