import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/shimmer_box.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 56,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: AppLogo(height: 148),
                  ),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 28),
            Text(
              'Smart Auto',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .slideY(begin: 0.12, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              'Your car\'s mechanic on the go',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
            ).animate().fadeIn(duration: 500.ms, delay: 220.ms),
            const SizedBox(height: 40),
            SizedBox(
              width: 140,
              child: const ShimmerBox(height: 4, borderRadius: 4),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
