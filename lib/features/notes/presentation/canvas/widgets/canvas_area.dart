import 'package:flutter/material.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/drawing_canvas.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/magic_trail_layer.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/pending_recognition_banner.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/selection_bounding_box.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/utils/selection_geometry.dart';
import '../../../../../core/constants/app_constants.dart';
import '../canvas_provider.dart';
import '../canvas_state.dart';
import 'tool_bar_widgets/eraser_cursor_layer.dart';

class CanvasArea extends StatefulWidget {
  final CanvasState state;
  final CanvasNotifier notifier;
  final TransformationController transformationController;
  final ValueChanged<Size> onViewportSizeChanged;
  final ValueChanged<Offset> onCanvasExpanded;
  final String selectedLanguage;
  final VoidCallback onEditPendingText;
  const CanvasArea(
      {super.key,
      required this.state,
      required this.notifier,
      required this.transformationController,
      required this.onViewportSizeChanged,
      required this.onCanvasExpanded,
      required this.selectedLanguage,
      required this.onEditPendingText});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  bool _initialScaleApplied = false;

  @override
  void didUpdateWidget(covariant CanvasArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.canvasExpansionVersion !=
        oldWidget.state.canvasExpansionVersion) {
      widget.onCanvasExpanded(widget.state.canvasExpansionShift);
    }
  }
//___________________________________________________
// eraser cursor
// Eraser radius on SCREEN, in logical pixels.
// Scene units * scale = this many pixels on screen at any zoom, so the
  // cursor ring has exactly the size of what is erased.
//  static const double _eraserScreenRadius = 14;

  /// Finger position in viewport coordinates. `null` = cursor hidden.
  /// Only the cursor layer listens to it, so moving the finger never
  /// rebuilds CanvasArea or the canvas.
  final ValueNotifier<Offset?> _eraserPointer = ValueNotifier<Offset?>(null);

  /// The finger that owns the cursor (other fingers are ignored).
  int? _eraserPointerId;

  bool get _isEraser => widget.state.currentTool == CanvasTool.eraser;

  @override
  void dispose() {
    _eraserPointer.dispose();
    super.dispose();
  }

  // Listener does NOT join the gesture arena and does not consume events,
  // so DrawingCanvas gets every touch exactly as before.
  void _onPointerDown(PointerDownEvent event) {
    if (!_isEraser || _eraserPointerId != null) return;
    _eraserPointerId = event.pointer;
    _eraserPointer.value = event.localPosition;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _eraserPointerId) return;
    _eraserPointer.value = event.localPosition;
  }

  // Used for both "up" and "cancel". Not guarded by the tool, so the cursor
  // is always removed when the finger leaves the screen.
  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _eraserPointerId) return;
    _eraserPointerId = null;
    _eraserPointer.value = null;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.biggest.width > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onViewportSizeChanged(constraints.biggest);
            if (_initialScaleApplied) return;
            final scale = constraints.biggest.width / AppConstants.pageWidth;
            widget.transformationController.value =
                Matrix4.diagonal3Values(scale, scale, 1);
            _initialScaleApplied = true;
          });
        }

        final isPan = widget.state.currentTool == CanvasTool.pan;
        final isMagic = widget.state.currentTool == CanvasTool.magic;
        final isLasso = widget.state.currentTool == CanvasTool.lasso;
        final fitScale = constraints.biggest.width / AppConstants.pageWidth;

        final selectionRect = (isLasso &&
                widget.state.hasSelection &&
                widget.state.marqueeRect ==
                    null) // not while a new marquee is dragged
            ? SelectionGeometry.boundsOf(
                strokes: widget.state.strokes,
                blocks: widget.state.blocks,
                selectedBlockIds: widget.state.selectedBlockIds,
                selectedStrokeIds: widget.state.selectedStrokeIds,
                page: widget.state.canvasSize,
              )
            : null;

        final selectionHasText = SelectionGeometry.containsText(
          blocks: widget.state.blocks,
          selectedBlockIds: widget.state.selectedBlockIds,
        );

        //Listener around the whole area, to know where the finger is.
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerEnd,
          onPointerCancel: _onPointerEnd,
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: widget.transformationController,
                constrained: false,
                panEnabled: isPan,
                scaleEnabled: true,
                minScale: fitScale,
                maxScale: 10,
                boundaryMargin: const EdgeInsets.all(200),
                child: SizedBox(
                  width: widget.state.canvasSize.width,
                  height: widget.state.canvasSize.height,
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
              if (_isEraser)
                Positioned.fill(
                  child: EraserCursorLayer(
                    position: _eraserPointer,
                    // radius: _eraserScreenRadius,
                    radius: widget.state.eraserSize,
                  ),
                ),
              if (selectionRect != null)
                Positioned.fill(
                  child: SelectionBoundingBox(
                    sceneRect: selectionRect,
                    transformationController: widget.transformationController,
                    showEdgeHandles: !selectionHasText, // text: corners only
                    onResizeStart: widget.notifier.beginResize,
                    onResizeUpdate: (handle, delta) =>
                        widget.notifier.resizeSelection(delta, handle),
                    onResizeEnd: widget.notifier.endResize,
                  ),
                ),
            ],
          ),
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
          eraserRadius: widget.state.getEffectiveEraserRadius(
              scale), // _eraserScreenRadius / scale, // was: 14 / scale
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
          eraserRadius: widget.state.eraserSize /
              scale, // _eraserScreenRadius / scale, // was: 14 / scale
        );
        return;

      default:
        final adjustedPoint = widget.notifier.checkAndExpandCanvas(point);
        widget.notifier.addPoint(adjustedPoint);
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
      //  widget.notifier.saveCurrentDrawing();
    }
  }
}
