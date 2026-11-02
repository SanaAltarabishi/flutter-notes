import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand (indigo)
  static const Color seedColor = Color(0xFF4F46E5);
  static const int defaultBookCoverValue = 0xFF4F46E5;
  static const int defaultInkValue = 0xFF000000;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFE0E7FF);

  // Secondary (teal)
  static const Color secondary = Color(0xFF0EA5A4);
  static const Color secondaryLight = Color(0xFFCCF5F1);

  // Accent (amber): small pops of warmth
  static const Color accent = Color(0xFFF59E0B);

  // Surfaces
  static const Color surface = Color(0xFFF6F7FD);
  static const Color surfaceVariant = Color(0xFFECEEF9);

  // Text
  static const Color textPrimary = Color(0xFF1B1B3A);
  static const Color textSecondary = Color(0xFF5A5E7A);

  // Borders
  static const Color border = Color(0xFFD5D9EE);

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

  static const Color lightGrey = Color(0xFFF2F3FA);
  static const Color greyBorder = Color(0xFFE0E3F0);
  static const Color greySurface = Color(0xFFEAECF6);
  static const Color greyText = Color(0xFF6A6F8C);

  // Page / Canvas
  static const Color pagePaper = Color(0xFFFFFEFA);
  static const Color pageLine = Color(0xFFDDE1F0);
  static const Color pageBorder = Color(0xFFE2E5F2);
  static const Color pageFold = Color(0xFFE8EAF3);

  static const Color bookSpineMiddle = Color(0x26000000);
  static const Color canvasSelection = Color(0x264F46E5); // primary, 15%

  // Book Card
  static const Color bookPage = Color(0xFFF3EEE5);
  static const Color bookShadow = Color(0x47000000);
  static const Color bookCoverShadow = Color(0x59000000);
  static const Color bookSpineDark = Color(0x73000000);
  static const Color bookSpineHighlight = Color(0x1FFFFFFF);
  static const Color bookHinge = Color(0x33000000);
  static const Color bookPageEdge = Color(0x0F000000);
  static const Color bookGloss = Color(0x29FFFFFF);
  static const Color bookDivider = Color(0x61FFFFFF);
  static const Color bookDateText = Color(0xB3FFFFFF);
  static const Color bookTitleShadow = Color(0x61000000);

  // Grid lines on the drawing page (slightly more visible than before)
  static const Color bookPageBackground = Color(0xFFE8EAF4);
}