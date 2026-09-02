import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../providers/issues_list_provider.dart';
import '../../models/help_request_model.dart';
import '../../providers/open_requests_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_page.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/scale_tap.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/premium_auto_geometrics.dart';
import '../../utils/offer_price_format.dart';

String _friendlyRequestsError(Object e) {
  final s = e.toString();
  if (s.contains('42P17') || s.contains('infinite recursion')) {
    return 'The server rules for requests were updated. Pull to refresh, or apply the latest Supabase migrations from this project.';
  }
  return 'Could not load requests. Check your connection and try again.';
}

String _friendlyIssuesError(Object e) {
  final s = e.toString();
  if (s.contains('42P17') || s.contains('infinite recursion')) {
    return 'Could not load issues due to a database policy loop. Update Supabase migrations, then retry.';
  }
  return 'Could not load issues. Try again in a moment.';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _requestsMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  Future<void> _syncLocation() async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;
    final loc = ref.read(locationServiceProvider);
    final pos = await loc.currentPosition();
    if (pos == null || !mounted) return;
    await ref.read(profileRepositoryProvider).updateProfile(user.id, {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    });
    ref.invalidate(profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final issuesAsync = ref.watch(recentIssuesProvider);
    final requestsAsync = ref.watch(openRequestsProvider);
    final name = profileAsync.valueOrNull?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: const FloatingAutoShapeAccents(),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(recentIssuesProvider);
              ref.invalidate(openRequestsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                    child: Row(
                      children: [
                        AppLogo(height: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $name',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'What do you need today?',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () =>
                              ref.read(themeModeProvider.notifier).toggleLightDark(),
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => context.push('/profile'),
                          icon: const Icon(Icons.person_outline),
                          tooltip: 'Profile',
                        ),
                        IconButton.filledTonal(
                          onPressed: () async {
                            await ref.read(authServiceProvider).signOut();
                            if (!context.mounted) return;
                            context.go('/login');
                          },
                          icon: const Icon(Icons.logout_rounded),
                          tooltip: 'Sign out',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.02, curve: Curves.easeOutCubic),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Hero(
                            tag: 'avatar',
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.9),
                                    AppColors.secondary.withValues(alpha: 0.85),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 34,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                backgroundImage: profileAsync.valueOrNull?.profileImage !=
                                        null
                                    ? CachedNetworkImageProvider(
                                        profileAsync.valueOrNull!.profileImage!,
                                      )
                                    : null,
                                child: profileAsync.valueOrNull?.profileImage == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 38,
                                        color: AppColors.secondary.withValues(alpha: 0.7),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap avatar to open profile',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tiles = <({String asset, String l, Color c, String route})>[
                          (
                            asset: 'assets/lottie/voiceissue.json',
                            l: 'Voice issue',
                            c: AppColors.primary,
                            route: '/ai-detection?mode=voice',
                          ),
                          (
                            asset: 'assets/lottie/imageissue.json',
                            l: 'Image issue',
                            c: AppColors.secondary,
                            route: '/ai-detection?mode=image',
                          ),
                          (
                            asset: 'assets/lottie/nearbyservices.json',
                            l: 'Nearby services',
                            c: AppColors.primary,
                            route: '/nearby-services',
                          ),
                          (
                            asset: 'assets/lottie/requesthelp.json',
                            l: 'Request help',
                            c: AppColors.secondary,
                            route: '/request/new',
                          ),
                        ];
                        final t = tiles[index];
                        return _QuickTile(
                          lottieAsset: t.asset,
                          label: t.l,
                          color: t.c,
                          onTap: () => context.push(t.route),
                        )
                            .animate()
                            .fadeIn(duration: 450.ms, delay: (70 * index).ms)
                            .slideY(
                              begin: 0.08,
                              curve: Curves.easeOutCubic,
                              duration: 450.ms,
                              delay: (70 * index).ms,
                            );
                      },
                      childCount: 4,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push('/requests/mine'),
                      icon: const Icon(Icons.list_alt_rounded, size: 22),
                      label: const Text('My requests'),
                      style: FilledButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _SectionHeading(
                      kicker: 'Diagnostics',
                      title: 'Recent issues',
                      trailing: TextButton.icon(
                        onPressed: () => context.push('/ai-detection'),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('New'),
                      ),
                    ),
                  ),
                ),
                issuesAsync.when(
                  data: (issues) {
                    if (issues.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _EmptyHintCard(
                            icon: Icons.auto_awesome_outlined,
                            title: 'No saved issues yet',
                            subtitle: 'Describe a symptom or send a photo for an AI diagnosis.',
                            actionLabel: 'Start diagnosis',
                            onAction: () => context.push('/ai-detection'),
                          ),
                        ),
                      );
                    }
                    return SliverList.builder(
                      itemCount: issues.length.clamp(0, 5),
                      itemBuilder: (context, i) {
                        final issue = issues[i];
                        final title =
                            issue.aiResponse?.issueName ?? 'Car issue';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: FadeSlidePage(
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.build_circle_outlined),
                                title: Text(title),
                                subtitle: Text(
                                  issue.description ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () =>
                                    context.push('/ai-result', extra: issue),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ShimmerBox(height: 72, borderRadius: 16),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: _DataErrorCard(
                      title: 'Could not load issues',
                      message: _friendlyIssuesError(e),
                      onRetry: () => ref.invalidate(recentIssuesProvider),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _SectionHeading(
                            kicker: 'Community',
                            title: 'Nearby requests',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<bool>(
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('List'),
                              icon: Icon(Icons.view_list_rounded, size: 18),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Map'),
                              icon: Icon(Icons.map_rounded, size: 18),
                            ),
                          ],
                          selected: {_requestsMap},
                          onSelectionChanged: (set) {
                            setState(() => _requestsMap = set.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                requestsAsync.when(
                  data: (list) {
                    if (_requestsMap) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: _RequestsMapPreview(
                            requests: list,
                            onOpenList: () => context.push('/requests'),
                          ),
                        ),
                      );
                    }
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _EmptyHintCard(
                            icon: Icons.handshake_outlined,
                            title: 'No open requests right now',
                            subtitle: 'When drivers post help nearby, they will appear here.',
                            actionLabel: 'Browse all requests',
                            onAction: () => context.push('/requests'),
                          ),
                        ),
                      );
                    }
                    return SliverList.builder(
                      itemCount: list.length.clamp(0, 6),
                      itemBuilder: (context, i) {
                        final r = list[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _NearbyRequestCard(
                            request: r,
                            onTap: () => context.push('/requests'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: ShimmerBox(height: 100, borderRadius: 22),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: _DataErrorCard(
                      title: 'Nearby requests unavailable',
                      message: _friendlyRequestsError(e),
                      onRetry: () => ref.invalidate(openRequestsProvider),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.kicker,
    required this.title,
    this.trailing,
  });

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.45,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (trailing case final Widget t) t,
      ],
    );
  }
}

class _DataErrorCard extends StatelessWidget {
  const _DataErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.14),
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 26, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHintCard extends StatelessWidget {
  const _EmptyHintCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.secondary.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.62),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _NearbyRequestCard extends StatelessWidget {
  const _NearbyRequestCard({required this.request, required this.onTap});

  final HelpRequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  if (request.description != null && request.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.58),
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (request.price != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Text(
                  formatOfferPriceLe(request.price)!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.lottieAsset,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String lottieAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Lottie.asset(
                  lottieAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsMapPreview extends ConsumerWidget {
  const _RequestsMapPreview({
    required this.requests,
    required this.onOpenList,
  });

  final List<HelpRequestModel> requests;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.map_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.85)),
            const SizedBox(height: 10),
            Text(
              'Open the full map to see markers, browse offers, and respond to drivers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: onOpenList,
              child: const Text('Open requests map'),
            ),
          ],
        ),
      ),
    );
  }
}
