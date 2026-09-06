import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/stroke.dart';

enum CanvasTool { pen, eraser, lasso }

//State = Snapshot of everything the UI currently needs to know.
class CanvasState {
  final List<Stroke> strokes;
  final List<Stroke> redoStack;
  final Color currentColor;
  final double strokeWidth;
  final CanvasTool currentTool;
  final bool isRecognizing;
  final String? recognizedText;
  // final String? error;
  final Failure? error;
  final Size canvasSize;
  final List<ContentBlock> blocks;

  const CanvasState({
    this.error,
    this.strokes = const [],
    this.redoStack = const [],
    this.currentColor = AppColors.black,
    this.strokeWidth = 3.0,
    this.currentTool = CanvasTool.pen,
    this.isRecognizing = false,
    this.recognizedText,
    //  this.error,
    this.canvasSize = Size.zero,
    this.blocks = const [],
  });
//copyWith gives us an easy way to create a new version of that state with only the things we want to change.
  CanvasState copyWith({
    List<Stroke>? strokes,
    List<Stroke>? redoStack,
    Color? currentColor,
    double? strokeWidth,
    CanvasTool? currentTool,
    bool? isRecognizing,
    String? recognizedText,
    //  String? error,
    Size? canvasSize,
    List<ContentBlock>? blocks,
    Failure? error,
    bool clearError = false,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      redoStack: redoStack ?? this.redoStack,
      currentColor: currentColor ?? this.currentColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      currentTool: currentTool ?? this.currentTool,
      isRecognizing: isRecognizing ?? this.isRecognizing,
      recognizedText: recognizedText ?? this.recognizedText,
      //   error: error,
      canvasSize: canvasSize ?? this.canvasSize,
      blocks: blocks ?? this.blocks,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
/*
CanvasState
    │
    ├── strokes       → what did I draw?
    ├── redoStack     → what can I redo?
    ├── currentColor  → what color am I using?
    ├── strokeWidth   → how thick is the pen?
    ├── currentTool   → what tool is selected?
    ├── isRecognizing → is recognition running?
    ├── recognizedText→ what was recognized?
    ├── error         → did something fail?
    ├── canvasSize    → how big is the canvas?
    └── blocks        → what blocks are on the page?
*/
