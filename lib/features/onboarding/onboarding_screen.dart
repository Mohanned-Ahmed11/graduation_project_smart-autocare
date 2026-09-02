import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/premium_auto_geometrics.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController(viewportFraction: 0.88);
  int _page = 0;

  static const _pages = [
    _OnboardPageData(
      asset: 'assets/lottie/vehicle.json',
      title: 'Welcome to SmartAutoCar',
      subtitle: 'Fix your car issues instantly with a tap.',
    ),
    _OnboardPageData(
      asset: 'assets/lottie/aichatbot.json',
      title: 'AI diagnosis',
      subtitle: 'Send voice or a photo—get clear, simple answers fast.',
    ),
    _OnboardPageData(
      asset: 'assets/lottie/taxi_app.json',
      title: 'Always on the move',
      subtitle: 'Find nearby garages, services, and help wherever you are.',
    ),
    _OnboardPageData(
      asset: 'assets/lottie/contact.json',
      title: 'Community & chat',
      subtitle: 'Ask drivers for help, chat, and agree on a fair price.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _pageFloat {
    if (!_controller.hasClients || !_controller.position.hasContentDimensions) {
      return _page.toDouble();
    }
    return _controller.page ?? _page.toDouble();
  }

  Future<void> _finish() async {
    if (!mounted) return;
    final hasSession =
        Env.hasSupabase && Supabase.instance.client.auth.currentSession != null;
    context.go(hasSession ? '/home' : '/login');
  }

  static const _ctaTextStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 16,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  Widget _buildOnboardingCtaChild() {
    final isLast = _page >= _pages.length - 1;
    if (isLast) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Get started', style: _ctaTextStyle),
          const SizedBox(width: 12),
          _CtaIconCapsule(
            icon: Icons.bolt_rounded,
            iconSize: 24,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Next', style: _ctaTextStyle),
        const SizedBox(width: 14),
        _CtaIconCapsule(
          key: ValueKey<int>(_page),
          icon: Icons.arrow_forward_rounded,
          iconSize: 22,
        )
            .animate()
            .fadeIn(duration: 280.ms, curve: Curves.easeOut)
            .slideX(begin: 0.15, end: 0, duration: 340.ms, curve: Curves.easeOutCubic)
            .then()
            .shimmer(
              delay: 400.ms,
              duration: 1400.ms,
              color: Colors.white.withValues(alpha: 0.35),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FloatingAutoShapeAccents(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: AppLogo(height: 56)
                              .animate(key: ValueKey<int>(_page))
                              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                              .scale(
                                begin: const Offset(0.82, 0.82),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .shimmer(
                                duration: 1400.ms,
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    clipBehavior: Clip.hardEdge,
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final delta = (_pageFloat - index).clamp(-1.0, 1.0);
                      final parallax = delta * 16;
                      final scale = 1 - (delta.abs() * 0.06);
                      final rotY = delta * -0.09;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                              ? constraints.maxWidth
                              : 360.0;
                          return ClipRect(
                            child: Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: maxW,
                                child: Center(
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Transform.translate(
                                      offset: Offset(parallax, 0),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(rotY),
                                        child: Opacity(
                                          opacity: (1 - delta.abs() * 0.45).clamp(0.55, 1.0),
                                          child: _OnboardSlide(
                                            key: ValueKey('${_pages[index].asset}_$index'),
                                            data: _pages[index],
                                            pageIndex: index,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _pages.length,
                    (i) => _OnboardPagerDot(active: i == _page),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Align(
                    alignment: _page < _pages.length - 1
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: AppColors.primary.withValues(alpha: 0.55),
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: _page < _pages.length - 1 ? 24 : 28,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        if (_page < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _finish();
                        }
                      },
                      child: _buildOnboardingCtaChild(),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(
                          delay: 800.ms,
                          duration: 2200.ms,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted pill with icon — sits beside CTA label on onboarding buttons.
class _CtaIconCapsule extends StatelessWidget {
  const _CtaIconCapsule({
    super.key,
    required this.icon,
    required this.iconSize,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.52),
            Colors.white.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(-1, -2),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}

/// Width is animated on the outer [AnimatedContainer]; decoration lives on an inner
/// [DecoratedBox] so Flutter never lerps between incompatible [BoxDecoration]s (avoids
/// negative shadow blur during transitions).
class _OnboardPagerDot extends StatelessWidget {
  const _OnboardPagerDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.elasticOut,
        width: active ? 30 : 7,
        height: 7,
        decoration: const BoxDecoration(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active ? null : Colors.grey.withValues(alpha: 0.35),
            gradient: active
                ? const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  const _OnboardPageData({
    required this.asset,
    required this.title,
    required this.subtitle,
  });
  final String asset;
  final String title;
  final String subtitle;
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({
    super.key,
    required this.data,
    required this.pageIndex,
  });

  final _OnboardPageData data;
  final int pageIndex;

  /// Bold entrance + subtle idle loop — no purple “card”; Lottie is the hero.
  Widget _animatedLottieCard(Widget child) {
    switch (pageIndex % 4) {
      case 0:
        // Elastic pop + gentle vertical float
        return Animate(
          onPlay: (c) => c.repeat(reverse: true),
          effects: [
            MoveEffect(
              begin: const Offset(0, -7),
              end: const Offset(0, 7),
              duration: 2800.ms,
              curve: Curves.easeInOut,
            ),
            RotateEffect(
              begin: -0.04,
              end: 0.04,
              duration: 3200.ms,
              curve: Curves.easeInOut,
            ),
          ],
          child: child
              .animate()
              .fadeIn(duration: 320.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.12, 0.12),
                duration: 780.ms,
                curve: Curves.elasticOut,
              )
              .rotate(begin: -0.14, end: 0, duration: 620.ms, curve: Curves.easeOutCubic),
        );
      case 1:
        // Whip from right, blur resolves, then horizontal drift
        return Animate(
          onPlay: (c) => c.repeat(reverse: true),
          effects: [
            MoveEffect(
              begin: const Offset(-10, 0),
              end: const Offset(10, 0),
              duration: 2400.ms,
              curve: Curves.easeInOut,
            ),
          ],
          child: child
              .animate()
              .fadeIn(duration: 280.ms)
              .slideX(begin: 0.42, duration: 620.ms, curve: Curves.easeOutBack)
              .blur(begin: const Offset(14, 14), end: Offset.zero, duration: 550.ms, curve: Curves.easeOut)
              .then(delay: 80.ms)
              .flipH(begin: 0.06, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
        );
      case 2:
        // “Drop from sky” + squash pulse idle
        return Animate(
          onPlay: (c) => c.repeat(reverse: true),
          effects: [
            ScaleEffect(
              begin: const Offset(1, 1),
              end: const Offset(1.04, 1.04),
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
          ],
          child: child
              .animate()
              .fadeIn(duration: 260.ms)
              .slideY(begin: -0.38, duration: 700.ms, curve: Curves.bounceOut)
              .scale(
                begin: const Offset(1.18, 0.82),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.easeOutCubic,
              )
              .then(delay: 120.ms)
              .shake(hz: 4, duration: 320.ms, curve: Curves.easeOut),
        );
      default:
        // Spiral-ish spin + orbit wobble
        return Animate(
          onPlay: (c) => c.repeat(reverse: true),
          effects: [
            MoveEffect(
              begin: const Offset(-6, -4),
              end: const Offset(6, 4),
              duration: 3500.ms,
              curve: Curves.easeInOut,
            ),
          ],
          child: child
              .animate()
              .fadeIn(duration: 300.ms)
              .rotate(begin: 0.35, end: 0, duration: 900.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.4, 0.4),
                duration: 900.ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .custom(
                duration: 500.ms,
                builder: (context, value, ch) {
                  final s = 1 + math.sin(value * math.pi) * 0.04;
                  return Transform.scale(scale: s, child: ch);
                },
              ),
        );
    }
  }

  Widget _animatedTitle(Text title) {
    final w = title
        .animate()
        .fadeIn(duration: 380.ms, delay: 90.ms);

    switch (pageIndex % 4) {
      case 0:
        return w.slideY(begin: 0.06, curve: Curves.easeOutCubic);
      case 1:
        return w.slideX(begin: 0.08, curve: Curves.easeOut);
      case 2:
        return w.blur(begin: const Offset(2, 0), end: Offset.zero, duration: 400.ms);
      default:
        return w
            .scale(begin: const Offset(0.96, 1), duration: 400.ms)
            .shake(hz: 2, duration: 280.ms, delay: 200.ms);
    }
  }

  Widget _animatedSubtitle(Text subtitle) {
    return subtitle
        .animate()
        .fadeIn(duration: 480.ms, delay: 140.ms)
        .slideY(
          begin: pageIndex.isEven ? 0.05 : -0.04,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth.clamp(260.0, 520.0)
            : 400.0;

        final lottie = SizedBox(
          height: 292,
          width: double.infinity,
          child: Lottie.asset(
            data.asset,
            fit: BoxFit.contain,
            repeat: true,
            frameRate: FrameRate.max,
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _animatedLottieCard(lottie),
                const SizedBox(height: 24),
                _animatedTitle(
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                _animatedSubtitle(
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
