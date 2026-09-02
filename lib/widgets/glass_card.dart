import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.03),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.52),
                    ],
            ),
            border: Border.all(
              width: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              if (isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
