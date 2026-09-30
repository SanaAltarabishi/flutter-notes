import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/stroke.dart';

enum CanvasTool { pen, eraser, lasso, highlighter, magic }

//State = Snapshot of everything the UI currently needs to know.
class CanvasState {
  final List<Stroke> strokes;
  final Color currentColor;
  final Color highlighterColor;
  final double strokeWidth;
  final double highlighterWidth;
  final CanvasTool currentTool;
  final bool isRecognizing;
  final Failure? error;
  final Size canvasSize;
  final List<ContentBlock> blocks;

  final bool canUndo;
  final bool canRedo;

  final String? pendingRecognizedText;
  final Rect? pendingRecognitionBounds;
  final Set<String> pendingRecognitionStrokeIds;

  // تحديد متعدد: بلوكات محفوظة + strokes حيّة بنفس الوقت
  final Set<String> selectedBlockIds;
  final Set<String> selectedStrokeIds;
  final Rect? marqueeRect;

  const CanvasState({
    this.error,
    this.strokes = const [],
    this.currentColor = AppColors.black,
    this.highlighterColor = Colors.yellow,
    this.strokeWidth = 3.0,
    this.highlighterWidth = 12.0,
    this.currentTool = CanvasTool.pen,
    this.isRecognizing = false,
    this.canvasSize = Size.zero,
    this.blocks = const [],
    this.canUndo = false,
    this.canRedo = false,
    this.pendingRecognizedText,
    this.pendingRecognitionBounds,
    this.pendingRecognitionStrokeIds = const {},
    this.selectedBlockIds = const {},
    this.selectedStrokeIds = const {},
    this.marqueeRect,
  });

  CanvasState copyWith({
    List<Stroke>? strokes,
    Color? currentColor,
    Color? highlighterColor,
    double? strokeWidth,
    double? highlighterWidth,
    CanvasTool? currentTool,
    bool? isRecognizing,
    Size? canvasSize,
    List<ContentBlock>? blocks,
    Failure? error,
    bool clearError = false,
    bool? canUndo,
    bool? canRedo,
    String? pendingRecognizedText,
    Rect? pendingRecognitionBounds,
    Set<String>? pendingRecognitionStrokeIds,
    bool clearPendingRecognition = false,
    Set<String>? selectedBlockIds,
    bool clearSelectedBlockIds = false,
    Set<String>? selectedStrokeIds,
    bool clearSelectedStrokeIds = false,
    Rect? marqueeRect,
    bool clearMarqueeRect = false,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      currentColor: currentColor ?? this.currentColor,
      highlighterColor: highlighterColor ?? this.highlighterColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      highlighterWidth: highlighterWidth ?? this.highlighterWidth,
      currentTool: currentTool ?? this.currentTool,
      isRecognizing: isRecognizing ?? this.isRecognizing,
      canvasSize: canvasSize ?? this.canvasSize,
      blocks: blocks ?? this.blocks,
      error: clearError ? null : (error ?? this.error),
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      pendingRecognizedText: clearPendingRecognition
          ? null
          : (pendingRecognizedText ?? this.pendingRecognizedText),
      pendingRecognitionBounds: clearPendingRecognition
          ? null
          : (pendingRecognitionBounds ?? this.pendingRecognitionBounds),
      pendingRecognitionStrokeIds: clearPendingRecognition
          ? const {}
          : (pendingRecognitionStrokeIds ?? this.pendingRecognitionStrokeIds),
      selectedBlockIds: clearSelectedBlockIds
          ? const {}
          : (selectedBlockIds ?? this.selectedBlockIds),
      selectedStrokeIds: clearSelectedStrokeIds
          ? const {}
          : (selectedStrokeIds ?? this.selectedStrokeIds),
      marqueeRect: clearMarqueeRect ? null : (marqueeRect ?? this.marqueeRect),
    );
  }

//___________________________________________________
  TextBlock? get selectedTextBlock {
    if (selectedBlockIds.length != 1 || selectedStrokeIds.isNotEmpty) {
      return null;
    }

    final selectedId = selectedBlockIds.first;

    for (final block in blocks) {
      if (block.id == selectedId && block is TextBlock) {
        return block;
      }
    }

    return null;
  }

//___________________________________________________
  bool get hasSelection =>
      selectedBlockIds.isNotEmpty || selectedStrokeIds.isNotEmpty;
//___________________________________________________
  bool get hasStrokeSelection => selectedStrokeIds.isNotEmpty;
}
