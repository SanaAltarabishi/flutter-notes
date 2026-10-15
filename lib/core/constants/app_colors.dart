import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color seedColor = Color.fromARGB(255, 146, 4, 108);
  static const int defaultBookCoverValue = 0xFF2196F3;
  static const int defaultInkValue = 0xFF000000;

  static const Color primary = Color(0xFF92046C);
  static const Color primaryDark = Color(0xFF6F034F);
  static const Color primaryLight = Color(0xFFF3D6EB);

  // Surfaces
  static const Color surface = Color(0xFFFFF8FC);
  static const Color surfaceVariant = Color(0xFFF9EAF4);
  // Text
  static const Color textPrimary = Color(0xFF3F2638);
  static const Color textSecondary = Color(0xFF765D70);
  // Borders
  static const Color border = Color(0xFFE2BDD5);
  // Error
  static final Color error = Colors.red.shade800;
  static final Color errorLight = Colors.red.shade50;

  // Common
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black45 = Colors.black45;
  static const Color transparent = Colors.transparent;
  static const Color red = Colors.red;
  static const Color blue = Colors.blue;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color purple = Colors.purple;
  static const Color yellow = Colors.yellow;
  static const Color grey = Colors.grey;
  static const Color blueGrey = Colors.blueGrey;
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color greyBorder = Color(0xFFE0E0E0);
  static const Color greySurface = Color(0xFFEEEEEE);
  static const Color greyText = Color(0xFF757575);
  static const Color pagePaper = Color(0xFFFFFEFA);
  static const Color pageLine = Color(0xFFD9DEE8);
  static const Color pageBorder = Color(0xFFE4E5E9);
  static const Color pageFold = Color(0xFFE8E8E5);
  static const Color bookSpineMiddle = Color(0x26000000);
  static const Color canvasSelection = Color(0x140000FF);
//_________________________________________________________

  // Book Card
  /// Color of the pages visible behind the book cover.
  static const Color bookPage = Color(0xFFF3EEE1);

  /// Shadow around the entire book.
  static const Color bookShadow = Color(0x47000000);

  /// Shadow underneath the cover.
  static const Color bookCoverShadow = Color(0x59000000);

  /// Dark shading used around the spine.
  static const Color bookSpineDark = Color(0x73000000);

  /// Lighter highlight on the spine.
  static const Color bookSpineHighlight = Color(0x1FFFFFFF);

  /// Groove between spine and cover.
  static const Color bookHinge = Color(0x33000000);

  /// Thin lines representing individual pages.
  static const Color bookPageEdge = Color(0x0F000000);

  /// Glossy highlight on the cover.
  static const Color bookGloss = Color(0x29FFFFFF);

  /// Divider under the book title.
  static const Color bookDivider = Color(0x61FFFFFF);

  /// Date text on the book cover.
  static const Color bookDateText = Color(0xB3FFFFFF);

  /// Text shadow on the book title.
  static const Color bookTitleShadow = Color(0x61000000);
//_________________________________________________________
  static final Color bookPageBackground = Colors.grey.shade200;
}
