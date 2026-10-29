import 'dart:math' as math;
import 'dart:ui';

import 'resize_handle_position.dart';

/// "Scale by (scaleX, scaleY) around [anchor]".
///
///   p' = anchor + (p - anchor) * scale
///
/// As a matrix:  T(anchor) * S(scaleX, scaleY) * T(-anchor)
class ResizeTransform {
  final Offset anchor;
  final double scaleX;
  final double scaleY;

  const ResizeTransform({
    required this.anchor,
    required this.scaleX,
    required this.scaleY,
  });

  /// True for corner drags (same scale on both axes).
  bool get isUniform => (scaleX - scaleY).abs() < 1e-9;

  /// True when nothing changes (scale 1 on both axes).
  bool get isIdentity => (scaleX - 1).abs() < 1e-9 && (scaleY - 1).abs() < 1e-9;

  Offset apply(Offset p) => Offset(
        anchor.dx + (p.dx - anchor.dx) * scaleX,
        anchor.dy + (p.dy - anchor.dy) * scaleY,
      );

  Rect applyToRect(Rect r) =>
      Rect.fromPoints(apply(r.topLeft), apply(r.bottomRight));
}

/// Pure math, no state. Call it on every drag update.
///
/// [startRect]  the selection bounds when the drag STARTED.
/// [delta]      TOTAL finger movement since the drag started (scene units).
///
/// It always starts from [startRect], never from the previous frame, so
/// there is no drift, and the handle never "detaches" from the finger after
/// hitting the minimum size.
ResizeTransform computeResizeTransform({
  required Rect startRect,
  required ResizeHandlePosition handle,
  required Offset delta,
  bool keepAspectRatio = true,
  double minSize = 10,
}) {
  const eps = 1e-6;
  final w0 = startRect.width;
  final h0 = startRect.height;
  final degenerateW = w0 <= eps;
  final degenerateH = h0 <= eps;

  // A selection that is already smaller than minSize may grow, not shrink.
  final minW = math.min(minSize, w0);
  final minH = math.min(minSize, h0);

  // 1. Move only the edges that this handle controls.
  var left = startRect.left;
  var right = startRect.right;
  var top = startRect.top;
  var bottom = startRect.bottom;

  if (handle.movesLeft) left += delta.dx;
  if (handle.movesRight) right += delta.dx;
  if (handle.movesTop) top += delta.dy;
  if (handle.movesBottom) bottom += delta.dy;

  // 2. Minimum size. The handle stops, the box never flips or collapses.
  if (handle.movesLeft) left = math.min(left, right - minW);
  if (handle.movesRight) right = math.max(right, left + minW);
  if (handle.movesTop) top = math.min(top, bottom - minH);
  if (handle.movesBottom) bottom = math.max(bottom, top + minH);

  // 3. Scale factors = new size / old size.
  var sx = degenerateW ? 1.0 : (right - left) / w0;
  var sy = degenerateH ? 1.0 : (bottom - top) / h0;

  // 4. Corners keep the aspect ratio: one factor for both axes.
  if (handle.isCorner && keepAspectRatio) {
    final double s;
    if (degenerateW && degenerateH) {
      s = 1.0;
    } else if (degenerateW) {
      s = sy;
    } else if (degenerateH) {
      s = sx;
    } else {
      s = math.max(sx, sy); // follow the axis the finger moved more on
    }
    sx = s;
    sy = s;
  }

  return ResizeTransform(
    anchor: handle.anchorOn(startRect),
    scaleX: sx,
    scaleY: sy,
  );
}