import 'package:flutter/material.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/drawing_canvas.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/magic_trail_layer.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/pending_recognition_banner.dart';
import '../../../../../core/constants/app_constants.dart';
import '../canvas_provider.dart';
import '../canvas_state.dart';

class CanvasArea extends StatelessWidget {
  final CanvasState state;
  final CanvasNotifier notifier;
  final String selectedLanguage;
  final VoidCallback onEditPendingText;
  const CanvasArea(
      {super.key,
      required this.state,
      required this.notifier,
      required this.selectedLanguage,
      required this.onEditPendingText});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.setCanvasSize(constraints.biggest);
        });

        return Stack(
          children: [
            _buildDrawingCanvas(),
            _buildMagicLayer(),
            _buildPendingRecognition(),
          ],
        );
      },
    );
  }

//___________________
  Widget _buildDrawingCanvas() {
    return DrawingCanvas(
      strokes: state.strokes,
      blocks: state.blocks,
      selectedBlockIds: state.selectedBlockIds,
      selectedStrokeIds: state.selectedStrokeIds,
      marqueeRect: state.marqueeRect,
      onStart: _handleStart,
      onUpdate: _handleUpdate,
      onEnd: _handleEnd,
    );
  }

//___________________
  Widget _buildMagicLayer() {
    if (state.currentTool != CanvasTool.magic) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: MagicTrailLayer(
        color: state.currentColor,
      ),
    );
  }

//___________________
  Widget _buildPendingRecognition() {
    final text = state.pendingRecognizedText;
    final bounds = state.pendingRecognitionBounds;

    if (text == null || bounds == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: bounds.left,
      top: (bounds.top - 56).clamp(0, double.infinity),
      child: PendingRecognitionBanner(
        text: text,
        textDirection: selectedLanguage == AppConstants.langArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        onConfirm: notifier.confirmRecognition,
        onDiscard: notifier.discardRecognition,
        onEdit: onEditPendingText,
      ),
    );
  }

//___________________
  void _handleStart(Offset point) {
    switch (state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        notifier.selectAt(point);
        return;

      case CanvasTool.eraser:
        notifier.startErase(point);
        return;

      default:
        notifier.startStroke(point);
    }
  }

//___________________
  void _handleUpdate(Offset point) {
    switch (state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        notifier.updateSelection(point);
        return;

      case CanvasTool.eraser:
        notifier.eraseAt(point);
        return;

      default:
        notifier.addPoint(point);
    }
  }

//___________________
  void _handleEnd() {
    switch (state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        notifier.endSelection();
        return;

      default:
        notifier.endStroke();
    }
  }

//___________________
}
