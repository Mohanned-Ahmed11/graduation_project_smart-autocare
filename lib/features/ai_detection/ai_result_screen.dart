import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../models/issue_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_auto_geometrics.dart';

class AiResultScreen extends StatefulWidget {
  const AiResultScreen({super.key, this.issue});

  final IssueModel? issue;

  @override
  State<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends State<AiResultScreen> {
  final Set<String> _open = {'explanation', 'causes', 'fix', 'cost'};

  void _toggle(String id) {
    setState(() {
      if (_open.contains(id)) {
        _open.remove(id);
      } else {
        _open.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.issue == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI result')),
        body: const Center(child: Text('No issue data')),
      );
    }
    final ai = widget.issue!.aiResponse;
    final title = ai?.issueName ?? 'Diagnosis';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Your diagnosis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
        ),
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.38,
                child: const PremiumAutoGeometrics(intensity: 0.72),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight + 8),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.22),
                              AppColors.secondary.withValues(alpha: 0.14),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(Icons.car_repair_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.95)),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 60.ms, duration: 420.ms)
                          .slideY(begin: 0.04, delay: 60.ms, duration: 420.ms),
                      if (ai?.urgency != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.secondary.withValues(alpha: 0.16),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'Urgency: ${ai!.urgency}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ExpandTile(
                      key: const ValueKey('explanation'),
                      title: 'Simple explanation',
                      icon: Icons.lightbulb_outline_rounded,
                      body: ai?.explanation ?? '—',
                      expanded: _open.contains('explanation'),
                      onTap: () => _toggle('explanation'),
                    )
                        .animate()
                        .fadeIn(delay: 140.ms, duration: 380.ms)
                        .slideX(begin: -0.02, delay: 140.ms, duration: 380.ms),
                    _ExpandTile(
                      key: const ValueKey('causes'),
                      title: 'Possible causes',
                      icon: Icons.troubleshoot_rounded,
                      body: ai?.possibleCauses ?? '—',
                      expanded: _open.contains('causes'),
                      onTap: () => _toggle('causes'),
                    )
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 380.ms)
                        .slideX(begin: -0.02, delay: 180.ms, duration: 380.ms),
                    _ExpandTile(
                      key: const ValueKey('fix'),
                      title: 'Step-by-step fix',
                      icon: Icons.build_circle_outlined,
                      body: ai?.fixSteps ?? '—',
                      expanded: _open.contains('fix'),
                      onTap: () => _toggle('fix'),
                    )
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 380.ms)
                        .slideX(begin: -0.02, delay: 220.ms, duration: 380.ms),
                    _ExpandTile(
                      key: const ValueKey('cost'),
                      title: 'Estimated cost',
                      icon: Icons.payments_outlined,
                      body: ai?.estimatedCost ?? '—',
                      expanded: _open.contains('cost'),
                      onTap: () => _toggle('cost'),
                    )
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 380.ms)
                        .slideX(begin: -0.02, delay: 260.ms, duration: 380.ms),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.push('/request/new'),
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('Request help from drivers'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandTile extends StatelessWidget {
  const _ExpandTile({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String body;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: Radius.circular(expanded ? 0 : 20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more_rounded, color: scheme.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.88),
                      ),
                ),
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}
