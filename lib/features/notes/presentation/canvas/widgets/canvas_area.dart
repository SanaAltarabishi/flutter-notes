import 'package:flutter/material.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/drawing_canvas.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/magic_trail_layer.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/pending_recognition_banner.dart';
import '../../../../../core/constants/app_constants.dart';
import '../canvas_provider.dart';
import '../canvas_state.dart';

class CanvasArea extends StatefulWidget {
  final CanvasState state;
  final CanvasNotifier notifier;
  final TransformationController transformationController;
  final ValueChanged<Size> onViewportSizeChanged;
  final String selectedLanguage;
  final VoidCallback onEditPendingText;
  const CanvasArea(
      {super.key,
      required this.state,
      required this.notifier,
      required this.transformationController,
      required this.onViewportSizeChanged,
      required this.selectedLanguage,
      required this.onEditPendingText});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  bool _initialScaleApplied = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.biggest.width > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onViewportSizeChanged(constraints.biggest);
            if (_initialScaleApplied) return;
            final scale =
                constraints.biggest.width / AppConstants.pageWidth;
            widget.transformationController.value =
                Matrix4.diagonal3Values(scale, scale, 1);
            _initialScaleApplied = true;
          });
        }

        final isPan = widget.state.currentTool == CanvasTool.pan;
        final isMagic = widget.state.currentTool == CanvasTool.magic;
        final fitScale = constraints.biggest.width / AppConstants.pageWidth;

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: widget.transformationController,
              constrained: false,
              panEnabled: isPan,
              scaleEnabled: isPan,
              minScale: fitScale,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(200),
              child: SizedBox(
                width: AppConstants.pageWidth,
                height: AppConstants.pageHeight,
                child: Stack(
                  children: [
                    if (isPan)
                      IgnorePointer(child: _buildDrawingCanvas())
                    else
                      _buildDrawingCanvas(),
                    _buildPendingRecognition(),
                  ],
                ),
              ),
            ),
            if (isMagic)
              Positioned.fill(
                child: _buildMagicLayer(),
              ),
          ],
        );
      },
    );
  }

//___________________
  Widget _buildDrawingCanvas() {
    return DrawingCanvas(
      strokes: widget.state.strokes,
      blocks: widget.state.blocks,
      selectedBlockIds: widget.state.selectedBlockIds,
      selectedStrokeIds: widget.state.selectedStrokeIds,
      marqueeRect: widget.state.marqueeRect,
      onStart: _handleStart,
      onUpdate: _handleUpdate,
      onEnd: _handleEnd,
    );
  }

//___________________
  Widget _buildMagicLayer() {
    if (widget.state.currentTool != CanvasTool.magic) {
      return const SizedBox.shrink();
    }

    return MagicTrailLayer(
      color: widget.state.currentColor,
    );
  }

//___________________
  Widget _buildPendingRecognition() {
    final text = widget.state.pendingRecognizedText;
    final bounds = widget.state.pendingRecognitionBounds;

    if (text == null || bounds == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: bounds.left,
      top: (bounds.top - 56).clamp(0, double.infinity),
      child: PendingRecognitionBanner(
        text: text,
        textDirection: widget.selectedLanguage == AppConstants.langArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        onConfirm: widget.notifier.confirmRecognition,
        onDiscard: widget.notifier.discardRecognition,
        onEdit: widget.onEditPendingText,
      ),
    );
  }

//___________________
  void _handleStart(Offset point) {
    switch (widget.state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        widget.notifier.selectAt(point);
        return;

      case CanvasTool.eraser:
        final scale = widget.transformationController.value.getMaxScaleOnAxis();
        widget.notifier.startErase(
          point,
          eraserRadius: 14 / scale,
        );
        return;

      default:
        widget.notifier.startStroke(point);
    }
  }

//___________________
  void _handleUpdate(Offset point) {
    switch (widget.state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        widget.notifier.updateSelection(point);
        return;

      case CanvasTool.eraser:
        final scale = widget.transformationController.value.getMaxScaleOnAxis();
        widget.notifier.eraseAt(
          point,
          eraserRadius: 14 / scale,
        );
        return;

      default:
        widget.notifier.addPoint(point);
    }
  }

//___________________
  void _handleEnd() {
    switch (widget.state.currentTool) {
      case CanvasTool.magic:
        return;

      case CanvasTool.lasso:
        widget.notifier.endSelection();
        return;

      default:
        widget.notifier.endStroke();
    }
  }
}
