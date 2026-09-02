import 'package:flutter/material.dart';

class FadeSlidePage extends StatelessWidget {
  const FadeSlidePage({
    super.key,
    required this.child,
    this.beginOffset = const Offset(0, 0.04),
  });

  final Widget child;
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              beginOffset.dx * (1 - value) * 40,
              beginOffset.dy * (1 - value) * 40,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
