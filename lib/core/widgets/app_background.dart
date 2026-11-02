// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:freenotes_app/core/constants/app_colors.dart';

// class AppBackground extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry padding;
//   final bool safeArea;
//   final Color? accentColor;

//   const AppBackground({
//     super.key,
//     required this.child,
//     this.padding = EdgeInsets.zero,
//     this.safeArea = true,
//     this.accentColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final primary = accentColor ?? AppColors.seedColor;
//     final theme = Theme.of(context);
//     final base = theme.colorScheme.surface;

//     Widget content = Stack(
//       clipBehavior: Clip.none,
//       children: [
//         // Top warm glow
//         Positioned(
//           top: -110,
//           right: -90,
//           child: _GlowCircle(
//             color: primary.withOpacity(0.24),
//             size: 360,
//           ),
//         ),

//         // Bottom warm glow
//         Positioned(
//           bottom: -140,
//           left: -110,
//           child: _GlowCircle(
//             color: primary.withOpacity(0.17),
//             size: 380,
//           ),
//         ),

//         // Soft secondary glow
//         Positioned(
//           top: 260,
//           left: -130,
//           child: _GlowCircle(
//             color: AppColors.secondary.withOpacity(0.10),
//             size: 260,
//           ),
//         ),

//         Padding(
//           padding: padding,
//           child: child,
//         ),
//       ],
//     );

//     if (safeArea) {
//       content = SafeArea(child: content);
//     }

//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Color.lerp(base, primary, 0.13)!,
//             base,
//             Color.lerp(base, primary, 0.09)!,
//           ],
//           stops: const [0.0, 0.52, 1.0],
//         ),
//       ),
//       child: content,
//     );
//   }
// }

// class _GlowCircle extends StatelessWidget {
//   final Color color;
//   final double size;

//   const _GlowCircle({
//     required this.color,
//     required this.size,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       child: ImageFiltered(
//         imageFilter: ImageFilter.blur(
//           sigmaX: 18,
//           sigmaY: 18,
//         ),
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: RadialGradient(
//               colors: [
//                 color.withOpacity(0.85),
//                 color.withOpacity(0.50),
//                 color.withOpacity(0.18),
//                 Colors.transparent,
//               ],
//               stops: const [0.0, 0.35, 0.7, 1.0],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';

/// App background: a soft "aurora" of three colors that slowly drifts, over a
/// light gradient, with a faint dot grid like a dotted notebook.
///
/// Same parameters as before, plus two optional ones:
/// - [animated]  slow floating movement (stops by itself when the screen is
///               not visible, or when the phone has "reduce animations" on)
/// - [intensity] 1 = normal, 0.6 = calm, 1.4 = loud
class AppBackground extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;

  /// If set (for example the color of a book), the aurora uses this color and
  /// two neighbours on the color wheel. If null, it uses the app palette.
  final Color? accentColor;

  final bool animated;
  final double intensity;

  const AppBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.safeArea = true,
    this.accentColor,
    this.animated = true,
    this.intensity = 1,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.animated && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Three colors for the aurora.
  List<Color> _auroraColors() {
    final accent = widget.accentColor;
    if (accent == null) {
      return const [AppColors.primary, AppColors.secondary, AppColors.accent];
    }

    // Keep the color alive: not too gray, not too dark, not too light.
    final hsl = HSLColor.fromColor(accent);
    Color shifted(double degrees) => hsl
        .withHue((hsl.hue + degrees) % 360)
        .withSaturation(hsl.saturation.clamp(0.55, 1.0))
        .withLightness(hsl.lightness.clamp(0.45, 0.62))
        .toColor();

    return [accent, shifted(-55), shifted(70)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final colors = _auroraColors();
    final strength = widget.intensity * (isDark ? 0.8 : 1.0);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.safeArea) content = SafeArea(child: content);

    // The colors are drawn edge to edge (also under the status bar).
    // SafeArea only moves the content.
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Light base gradient
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(base, colors[0], 0.14)!,
                base,
                Color.lerp(base, colors[1], 0.12)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // 2) The moving colors. Own layer: only this layer repaints while it
        //    moves, the screen content on top is not rebuilt.
        RepaintBoundary(
          child: CustomPaint(
            painter: _AuroraPainter(
              progress: _controller,
              colors: colors,
              strength: strength,
            ),
          ),
        ),

        // 3) Faint dotted-notebook texture. Painted once.
        RepaintBoundary(
          child: CustomPaint(
            painter: _DotGridPainter(
              color:
                  theme.colorScheme.onSurface.withOpacity(isDark ? 0.07 : 0.05),
            ),
          ),
        ),

        // 4) The screen
        content,
      ],
    );
  }
}

//____________________________________________________________
class _Blob {
  const _Blob({
    required this.colorIndex,
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.drift,
    required this.phase,
  });

  final int colorIndex; // which of the 3 colors
  final double x; // center, as a fraction of the width
  final double y; // center, as a fraction of the height
  final double radius; // as a fraction of the width
  final double alpha; // strength at the center (0..1)
  final double drift; // how far it floats (fraction of the size)
  final double phase; // so the blobs do not move together
}

const List<_Blob> _blobs = [
  _Blob(
      colorIndex: 0,
      x: 0.88,
      y: 0.02,
      radius: 0.85,
      alpha: 0.50,
      drift: 0.05,
      phase: 0.0),
  _Blob(
      colorIndex: 1,
      x: 0.02,
      y: 0.98,
      radius: 0.95,
      alpha: 0.42,
      drift: 0.05,
      phase: 2.1),
  _Blob(
      colorIndex: 2,
      x: -0.05,
      y: 0.42,
      radius: 0.60,
      alpha: 0.30,
      drift: 0.06,
      phase: 4.2),
  _Blob(
      colorIndex: 1,
      x: 1.05,
      y: 0.62,
      radius: 0.55,
      alpha: 0.26,
      drift: 0.05,
      phase: 1.3),
  _Blob(
      colorIndex: 2,
      x: 0.18,
      y: 0.00,
      radius: 0.50,
      alpha: 0.28,
      drift: 0.04,
      phase: 3.3),
];

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.progress,
    required this.colors,
    required this.strength,
  }) : super(repaint: progress); // repaint on every animation tick

  final Animation<double> progress;
  final List<Color> colors;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    // 0..2π. Only whole multiples of it are used below, so the loop has no jump.
    final angle = progress.value * 2 * math.pi;

    for (final blob in _blobs) {
      final center = Offset(
        (blob.x + blob.drift * math.sin(angle + blob.phase)) * size.width,
        (blob.y + blob.drift * math.cos(angle + blob.phase)) * size.height,
      );
      final radius = blob.radius * size.width;
      final color = colors[blob.colorIndex];
      final a = (blob.alpha * strength).clamp(0.0, 1.0);

      final shader = RadialGradient(
        colors: [
          color.withOpacity(a),
          color.withOpacity(a * 0.45),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.strength != strength || !listEquals(old.colors, colors);
}

//____________________________________________________________
class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;
  static const double _gap = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      for (double y = _gap / 2; y < size.height; y += _gap)
        for (double x = _gap / 2; x < size.width; x += _gap) Offset(x, y),
    ];

    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
