import 'package:flutter/material.dart';

class StaggeredFadeSlide extends StatelessWidget {
  final Widget child;
  final int index;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = Duration(milliseconds: 280 + index * 45);
    final delay = (index * 45) / totalDuration.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: totalDuration,
      curve: Interval(
        delay.clamp(0, 1),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
