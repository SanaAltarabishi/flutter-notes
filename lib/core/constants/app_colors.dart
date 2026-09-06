import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color seedColor = Color.fromARGB(255, 146, 4, 108);

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
  static const Color error = Color(0xFFBA3D58);
  static const Color errorLight = Color(0xFFFBE5EA);
  // Common
  static const Color white = Colors.white;
  static const Color black = Colors.black;
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
}
