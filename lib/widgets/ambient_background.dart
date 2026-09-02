import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Layered mesh gradient and soft orbs tuned to brand #7289FF.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.immersive = false,
  });

  final Widget child;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orbOpacity = immersive ? 0.42 : 0.28;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      AppColors.surfaceDark,
                      Color(0xFF0D1020),
                      Color(0xFF12182E),
                    ]
                  : const [
                      Color(0xFFF8F9FF),
                      AppColors.surfaceLight,
                      Color(0xFFE8ECFF),
                    ],
            ),
          ),
        ),
        if (!isDark)
          _GlowOrb(
            color: AppColors.primary.withValues(alpha: orbOpacity),
            size: immersive ? 300 : 240,
            top: -50,
            right: -70,
          ),
        _GlowOrb(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.32 : 0.18),
          size: immersive ? 260 : 200,
          bottom: immersive ? 90 : 130,
          left: -60,
        ),
        if (isDark)
          _GlowOrb(
            color: AppColors.primary.withValues(alpha: 0.16),
            size: 180,
            top: 160,
            right: -30,
          ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
