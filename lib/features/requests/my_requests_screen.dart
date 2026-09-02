import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/help_request_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/my_requests_provider.dart';
import '../../providers/open_requests_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/offer_price_format.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_auto_geometrics.dart';
import '../../widgets/shimmer_box.dart';
import 'request_review_offers_dialog.dart';

Future<void> _confirmDeleteRequest(
  BuildContext context,
  WidgetRef ref,
  HelpRequestModel r,
) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete request?'),
      content: Text(
        r.status == 'accepted'
            ? 'This removes the request and related chat. Drivers will no longer see it.'
            : 'This cannot be undone. Pending driver offers will be removed.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(requestsRepositoryProvider).deleteRequest(r.id);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(myRequestPendingCountsProvider);
    ref.invalidate(openRequestsProvider);
    ref.invalidate(requestsFeedProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'open':
      return Icons.radar_rounded;
    case 'accepted':
      return Icons.verified_rounded;
    case 'completed':
      return Icons.check_circle_outline_rounded;
    default:
      return Icons.flag_outlined;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Open';
    case 'accepted':
      return 'Accepted';
    case 'completed':
      return 'Completed';
    default:
      return status;
  }
}

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRequestsProvider);
    final countsAsync = ref.watch(myRequestPendingCountsProvider);
    final uid = ref.watch(authUserProvider).valueOrNull?.id;
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'My requests',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
        centerTitle: false,
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
                opacity: 0.42,
                child: const PremiumAutoGeometrics(intensity: 0.85),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.55,
                child: const FloatingAutoShapeAccents(),
              ),
            ),
          ),
          RefreshIndicator(
            edgeOffset: kToolbarHeight + MediaQuery.paddingOf(context).top,
            onRefresh: () async {
              ref.invalidate(myRequestsProvider);
              ref.invalidate(myRequestPendingCountsProvider);
            },
            child: async.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, kToolbarHeight + MediaQuery.paddingOf(context).top + 16, 20, 24 + bottom),
                children: [
                  const ShimmerBox(height: 22, width: 180, borderRadius: 10),
                  const SizedBox(height: 20),
                  ...List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(height: 118, borderRadius: 22),
                    ).animate().fadeIn(delay: (60 * i).ms, duration: 280.ms),
                  ),
                ],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, kToolbarHeight + MediaQuery.paddingOf(context).top + 16, 20, 24 + bottom),
                children: [
                  GlassCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 44, color: scheme.error.withValues(alpha: 0.75)),
                        const SizedBox(height: 14),
                        Text(
                          'Could not load',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text('$e', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              data: (list) {
                if (list.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, kToolbarHeight + MediaQuery.paddingOf(context).top + 20, 20, 28 + bottom),
                    children: [
                      GlassCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.22),
                                    AppColors.secondary.withValues(alpha: 0.14),
                                  ],
                                ),
                              ),
                              child: Icon(Icons.handshake_rounded, size: 44, color: AppColors.primary.withValues(alpha: 0.9)),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'No requests yet',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Post a help request — driver offers show up here in real time.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.56),
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 26),
                            FilledButton.icon(
                              onPressed: () => context.push('/request/new'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create request'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                          .slideY(begin: 0.04, duration: 420.ms, curve: Curves.easeOutCubic),
                    ],
                  );
                }

                final counts = countsAsync.valueOrNull ?? {};

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    kToolbarHeight + MediaQuery.paddingOf(context).top + 10,
                    18,
                    20 + bottom,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final pending = counts[r.id] ?? 0;
                    return _MyRequestTile(
                          request: r,
                          pendingCount: pending,
                          statusLabel: _statusLabel(r.status),
                          statusIcon: _statusIcon(r.status),
                          priceLabel: formatOfferPriceLe(r.price),
                          onDelete: uid != null && r.userId == uid
                              ? () => _confirmDeleteRequest(context, ref, r)
                              : null,
                          onReview: r.status == 'open' && uid != null && r.userId == uid
                              ? () => openRequestReviewOffersDialog(context, ref, r)
                              : null,
                          onChat: () async {
                            final chatId =
                                await ref.read(requestsRepositoryProvider).findChatIdForRequest(r.id);
                            if (!context.mounted) return;
                            if (chatId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No chat yet — accept a driver first.')),
                              );
                              return;
                            }
                            if (context.mounted) {
                              context.push('/chat/$chatId?requestId=${r.id}');
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: (45 * i).ms, duration: 380.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.05, delay: (45 * i).ms, duration: 380.ms, curve: Curves.easeOutCubic);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRequestTile extends StatelessWidget {
  const _MyRequestTile({
    required this.request,
    required this.pendingCount,
    required this.statusLabel,
    required this.statusIcon,
    this.priceLabel,
    this.onDelete,
    this.onReview,
    required this.onChat,
  });

  final HelpRequestModel request;
  final int pendingCount;
  final String statusLabel;
  final IconData statusIcon;
  final String? priceLabel;
  final VoidCallback? onDelete;
  final VoidCallback? onReview;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Icon(Icons.support_agent_rounded, color: AppColors.primary.withValues(alpha: 0.95), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                            height: 1.25,
                          ),
                    ),
                    if (priceLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.primary.withValues(alpha: 0.11),
                          ),
                          child: Text(
                            priceLabel!,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: request.status == 'open'
                          ? AppColors.secondary.withValues(alpha: 0.16)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 15, color: scheme.onSurface.withValues(alpha: 0.75)),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete request',
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.delete_outline_rounded, color: scheme.error.withValues(alpha: 0.88), size: 22),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
          if (request.description != null && request.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 58),
              child: Text(
                request.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.56),
                      height: 1.35,
                    ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReview != null && request.status == 'open')
                  FilledButton.tonal(
                    onPressed: onReview,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      pendingCount > 0 ? 'Review offers ($pendingCount)' : 'Review offers',
                    ),
                  ),
                if (request.status == 'accepted')
                  OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
