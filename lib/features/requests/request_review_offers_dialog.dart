import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/help_request_model.dart';
import '../../models/request_response_item.dart';
import '../../providers/app_providers.dart';
import '../../providers/my_requests_provider.dart';
import '../../providers/open_requests_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

/// Centered glass dialog: list pending drivers, accept one, then navigate to chat.
Future<void> openRequestReviewOffersDialog(
  BuildContext navigatorContext,
  WidgetRef ref,
  HelpRequestModel request,
) async {
  final user = ref.read(authUserProvider).valueOrNull;
  if (user == null || user.id != request.userId) return;
  final repo = ref.read(requestsRepositoryProvider);
  List<RequestResponseItem> offers;
  try {
    offers = await repo.listPendingResponses(request.id);
  } catch (e) {
    if (navigatorContext.mounted) {
      ScaffoldMessenger.of(navigatorContext).showSnackBar(SnackBar(content: Text('$e')));
    }
    return;
  }
  if (!navigatorContext.mounted) return;

  await showDialog<void>(
    context: navigatorContext,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final inset = MediaQuery.paddingOf(dialogContext);
      final dialogW = math.min(440.0, size.width - 32);
      final dialogH = math.min(size.height * 0.68, 520.0 + inset.bottom);

      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, inset.top + 12, 16, inset.bottom + 12),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              borderRadius: 28,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: dialogW,
                height: dialogH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review offers',
                                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(dialogContext)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.58),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: offers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 48,
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending offers yet',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Drivers who tap "I\'m interested" will show up here.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(dialogContext)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.55),
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              itemCount: offers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final o = offers[i];
                                final km = o.distanceKmFromRequest;
                                return GlassCard(
                                  borderRadius: 18,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary.withValues(alpha: 0.18),
                                              AppColors.secondary.withValues(alpha: 0.12),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.driverName ?? 'Driver',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(dialogContext)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                            if (km != null)
                                              Text(
                                                '~${km.toStringAsFixed(1)} km from your request pin',
                                                style: Theme.of(dialogContext).textTheme.labelSmall?.copyWith(
                                                      color: Theme.of(dialogContext)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(alpha: 0.55),
                                                    ),
                                              ),
                                            if (o.createdAt != null)
                                              Text(
                                                MaterialLocalizations.of(dialogContext)
                                                    .formatShortDate(o.createdAt!),
                                                style: Theme.of(dialogContext).textTheme.labelSmall?.copyWith(
                                                      color: Theme.of(dialogContext)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(alpha: 0.45),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () async {
                                          try {
                                            await repo.acceptResponseAsRequester(
                                              responseId: o.id,
                                              requesterUserId: user.id,
                                            );
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
                                            ref.invalidate(requestsFeedProvider);
                                            ref.invalidate(openRequestsProvider);
                                            ref.invalidate(myRequestsProvider);
                                            ref.invalidate(myRequestPendingCountsProvider);
                                            final chatId = await repo.findChatIdForRequest(request.id);
                                            if (navigatorContext.mounted && chatId != null) {
                                              GoRouter.of(navigatorContext)
                                                  .go('/chat/$chatId?requestId=${request.id}');
                                            }
                                          } catch (e) {
                                            if (navigatorContext.mounted) {
                                              ScaffoldMessenger.of(navigatorContext).showSnackBar(
                                                SnackBar(content: Text('$e')),
                                              );
                                            }
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
