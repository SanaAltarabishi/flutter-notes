// import 'package:flutter/material.dart';
// import 'package:freenotes_app/core/constants/app_constants.dart';

// class CanvasScene {
//   CanvasScene._();

//   // How much extra canvas around the page, as a multiple of the page size.
//   // 1 = the scene is 3x3 pages. Increase it for a bigger canvas.
//   static const double marginFactor = 1;

//   static const double marginX = AppConstants.pageWidth * marginFactor;
//   static const double marginY = AppConstants.pageHeight * marginFactor;

//   /// Where the page's top-left corner is inside the scene.
//   static const Offset origin = Offset(marginX, marginY);

//   /// Size of the whole scene (the child of InteractiveViewer).
//   static const Size size = Size(
//     AppConstants.pageWidth + 2 * marginX,
//     AppConstants.pageHeight + 2 * marginY,
//   );

//   /// The right / bottom edge of the canvas in WORLD coordinates.
//   /// Text wraps here, so it uses this instead of the page width.
//   static const Size worldExtent = Size(
//     AppConstants.pageWidth + marginX,
//     AppConstants.pageHeight + marginY,
//   );

//   /// Smallest scale (the most zoomed out) at which the scene still covers
//   /// the whole viewport, so no empty area is ever visible.
//   static double coverScale(Size viewport) {
//     final byWidth = viewport.width / size.width;
//     if (!viewport.height.isFinite || viewport.height <= 0) return byWidth;

//     final byHeight = viewport.height / size.height;
//     return byWidth > byHeight ? byWidth : byHeight;
//   }

//   /// The normal view: the page fills the screen width.
//   static double homeScale(Size viewport) {
//     final byPage = viewport.width / AppConstants.pageWidth;
//     final cover = coverScale(viewport);
//     return byPage > cover ? byPage : cover;
//   }

//   /// A view with the page's top-left corner at the top-left of the screen.
//   static Matrix4 homeView(double scale) {
//     final tx = -origin.dx * scale;
//     final ty = -origin.dy * scale;
//     // column-major: scale on the diagonal, translation in the last column
//     return Matrix4(
//       scale, 0, 0, 0, //
//       0, scale, 0, 0, //
//       0, 0, 1, 0, //
//       tx, ty, 0, 1,
//     );
//   }
// }
