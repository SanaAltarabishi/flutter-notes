
import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/utils/resize_handle_position.dart';


/// Resize handles around the selection.
///
/// Put it in the VIEWPORT (outside the InteractiveViewer), as a sibling
/// above it, wrapped in Positioned.fill. Why not inside the scene:
/// - handles keep the same touch size on screen at any zoom,
/// - their touches never reach the canvas below.
///
/// This widget only reports drags. It does not know about strokes or text.
class SelectionBoundingBox extends StatelessWidget {
  /// Selection bounds in SCENE coordinates.
  final Rect sceneRect;
  final TransformationController transformationController;

  /// Edge handles stretch (non-uniform). Hide them for text.
  final bool showEdgeHandles;

  /// A thin solid outline around the whole selection (useful when several
  /// items are selected). Off by default: the painter already draws boxes.
  final bool showOutline;

  final VoidCallback onResizeStart;

  /// [sceneDelta] = TOTAL movement since the drag started, in scene units.
  final void Function(ResizeHandlePosition handle, Offset sceneDelta)
      onResizeUpdate;
  final VoidCallback onResizeEnd;

  const SelectionBoundingBox({
    super.key,
    required this.sceneRect,
    required this.transformationController,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    this.showEdgeHandles = true,
    this.showOutline = false,
  });

  static const double _minHitSize = 24;
  static const double _maxHitSize = 44;
  static const double _visibleSize = 14;

  @override
  Widget build(BuildContext context) {
    // Rebuilds only this layer when the user pans / zooms.
    return AnimatedBuilder(
      animation: transformationController,
      builder: (context, _) {
        // scene -> screen
        final rect = MatrixUtils.transformRect(
          transformationController.value,
          sceneRect,
        );

        // Big touch target, but smaller for tiny selections so that the
        // hit boxes do not cover each other.
        final hit = (rect.shortestSide / 2).clamp(_minHitSize, _maxHitSize);

        final handles = <ResizeHandlePosition>[
          // edges first, corners last = corners win when they overlap
          if (showEdgeHandles && rect.width > hit * 2.5) ...[
            ResizeHandlePosition.top,
            ResizeHandlePosition.bottom,
          ],
          if (showEdgeHandles && rect.height > hit * 2.5) ...[
            ResizeHandlePosition.left,
            ResizeHandlePosition.right,
          ],
          ResizeHandlePosition.topLeft,
          ResizeHandlePosition.topRight,
          ResizeHandlePosition.bottomLeft,
          ResizeHandlePosition.bottomRight,
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showOutline)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blue, width: 1),
                    ),
                  ),
                ),
              ),
            for (final handle in handles)
              _ResizeHandle(
                key: ValueKey(handle),
                position: handle,
                center: handle.pointOn(rect),
                hitSize: hit,
                visibleSize: _visibleSize,
                controller: transformationController,
                onStart: onResizeStart,
                onUpdate: onResizeUpdate,
                onEnd: onResizeEnd,
              ),
          ],
        );
      },
    );
  }
}

//__________________________
class _ResizeHandle extends StatefulWidget {
  final ResizeHandlePosition position;
  final Offset center;
  final double hitSize;
  final double visibleSize;
  final TransformationController controller;
  final VoidCallback onStart;
  final void Function(ResizeHandlePosition, Offset) onUpdate;
  final VoidCallback onEnd;

  const _ResizeHandle({
    super.key,
    required this.position,
    required this.center,
    required this.hitSize,
    required this.visibleSize,
    required this.controller,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  int? _pointerId; // only one finger drives a handle
  Offset _startPosition = Offset.zero; // screen coordinates
  double _scale = 1;

  // Raw pointer events instead of GestureDetector.onPan:
  // - a pan gesture starts only after ~36 px of movement (touch slop), so
  //   the handle would feel late and jump,
  // - Listener does not join the gesture arena, and with `opaque` it stops
  //   the hit test here, so the canvas below never sees this touch.
  void _onDown(PointerDownEvent e) {
    if (_pointerId != null) return;
    _pointerId = e.pointer;
    _startPosition = e.position;
    _scale = widget.controller.value.getMaxScaleOnAxis();
    widget.onStart();
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointerId) return;
    final screenDelta = e.position - _startPosition;
    // screen -> scene: the viewer only scales uniformly and translates
    widget.onUpdate(widget.position, screenDelta / _scale);
  }

  void _onEnd(PointerEvent e) {
    if (e.pointer != _pointerId) return;
    _pointerId = null;
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final isCorner = widget.position.isCorner;

    return Positioned(
      left: widget.center.dx - widget.hitSize / 2,
      top: widget.center.dy - widget.hitSize / 2,
      width: widget.hitSize,
      height: widget.hitSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onEnd,
        onPointerCancel: _onEnd,
        child: Center(
          child: Container(
            width: widget.visibleSize,
            height: widget.visibleSize,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.circular(isCorner ? widget.visibleSize / 2 : 3),
              border: Border.all(color: AppColors.blue, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}