import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/notification_chime.dart';
import 'glass_card.dart';

/// Modal offer alert + optional chime when app is in foreground.
Future<void> showIncomingOfferDialog(
  BuildContext context, {
  required String requestTitle,
}) async {
  final binding = WidgetsBinding.instance;
  if (binding.lifecycleState != AppLifecycleState.resumed) return;
  if (!context.mounted) return;

  unawaited(playNotificationChime());

  final label = requestTitle.trim().isEmpty ? 'Your request' : '"$requestTitle"';

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassCard(
          borderRadius: 26,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.secondary.withValues(alpha: 0.14),
                        ],
                      ),
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: AppColors.primary.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'New driver offer',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Someone is interested in helping. Review offers on My requests.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.58),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ctx.go('/requests/mine');
                      },
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
