import 'dart:ui';

/// The 8 handles around the selection box.
enum ResizeHandlePosition {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

extension ResizeHandlePositionX on ResizeHandlePosition {
  bool get movesLeft =>
      this == ResizeHandlePosition.topLeft ||
      this == ResizeHandlePosition.left ||
      this == ResizeHandlePosition.bottomLeft;

  bool get movesRight =>
      this == ResizeHandlePosition.topRight ||
      this == ResizeHandlePosition.right ||
      this == ResizeHandlePosition.bottomRight;

  bool get movesTop =>
      this == ResizeHandlePosition.topLeft ||
      this == ResizeHandlePosition.top ||
      this == ResizeHandlePosition.topRight;

  bool get movesBottom =>
      this == ResizeHandlePosition.bottomLeft ||
      this == ResizeHandlePosition.bottom ||
      this == ResizeHandlePosition.bottomRight;

  bool get isCorner => (movesLeft || movesRight) && (movesTop || movesBottom);

  /// Where this handle sits on [rect].
  Offset pointOn(Rect rect) {
    final x = movesLeft
        ? rect.left
        : movesRight
            ? rect.right
            : rect.center.dx;
    final y = movesTop
        ? rect.top
        : movesBottom
            ? rect.bottom
            : rect.center.dy;
    return Offset(x, y);
  }

  /// The point that stays FIXED while this handle is dragged:
  /// the opposite corner, or the middle of the opposite edge.
  Offset anchorOn(Rect rect) {
    final x = movesLeft
        ? rect.right
        : movesRight
            ? rect.left
            : rect.center.dx;
    final y = movesTop
        ? rect.bottom
        : movesBottom
            ? rect.top
            : rect.center.dy;
    return Offset(x, y);
  }
}