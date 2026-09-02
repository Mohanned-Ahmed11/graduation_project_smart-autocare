import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/router/app_router.dart';
import '../providers/app_providers.dart';
import '../providers/my_requests_provider.dart';
import '../providers/open_requests_provider.dart';
import '../utils/notification_chime.dart';

/// When the requester accepts this user's pending offer: chime + open chat action.
class IncomingAcceptListener extends ConsumerStatefulWidget {
  const IncomingAcceptListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingAcceptListener> createState() => _IncomingAcceptListenerState();
}

class _IncomingAcceptListenerState extends ConsumerState<IncomingAcceptListener> {
  RealtimeChannel? _channel;
  String? _boundUserId;
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = ref.listenManual<AsyncValue<User?>>(
      authUserProvider,
      (prev, next) {
        next.whenData((user) {
          if (user == null) {
            _unbind();
          } else {
            _bind(user.id);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _unbind() {
    _channel?.unsubscribe();
    _channel = null;
    _boundUserId = null;
  }

  void _bind(String userId) {
    if (_boundUserId == userId && _channel != null) return;
    _unbind();
    _boundUserId = userId;
    final client = ref.read(supabaseClientProvider);
    _channel = client.channel('driver_accept_$userId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'request_responses',
          callback: (payload) => _onUpdate(userId, payload),
        )
        .subscribe();
  }

  Future<void> _onUpdate(String userId, PostgresChangePayload payload) async {
    final row = payload.newRecord;
    if (row['driver_id']?.toString() != userId) return;
    if (row['status']?.toString() != 'accepted') return;
    final requestId = row['request_id']?.toString();
    if (requestId == null) return;
    if (!mounted) return;

    ref.invalidate(requestsFeedProvider);
    ref.invalidate(openRequestsProvider);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(myRequestPendingCountsProvider);

    unawaited(playNotificationChime());

    final repo = ref.read(requestsRepositoryProvider);
    final chatId = await repo.findChatIdForRequest(requestId);
    if (!mounted) return;

    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;

    if (chatId != null) {
      GoRouter.of(navCtx).go('/chat/$chatId?requestId=$requestId');
    } else {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Requester accepted — open the request to chat.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _authSub?.close();
    _authSub = null;
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
