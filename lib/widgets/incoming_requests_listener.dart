import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/router/app_router.dart';
import '../providers/app_providers.dart';
import '../providers/open_requests_provider.dart';
import '../utils/notification_chime.dart';

/// Refreshes open request feeds when someone publishes a new open request.
class IncomingRequestsListener extends ConsumerStatefulWidget {
  const IncomingRequestsListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingRequestsListener> createState() => _IncomingRequestsListenerState();
}

class _IncomingRequestsListenerState extends ConsumerState<IncomingRequestsListener> {
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
    _channel = client.channel('open_requests_$userId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'requests',
          callback: (payload) => _onInsert(userId, payload),
        )
        .subscribe();
  }

  Future<void> _onInsert(String userId, PostgresChangePayload payload) async {
    final row = payload.newRecord;
    if (row['status']?.toString() != 'open') return;
    if (row['user_id']?.toString() == userId) return;
    if (!mounted) return;

    ref.invalidate(openRequestsProvider);
    ref.invalidate(requestsFeedProvider);

    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;

    unawaited(playNotificationChime());

    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;
    final title = (row['title'] as String?)?.trim();
    final label = title == null || title.isEmpty ? 'New help request nearby' : 'New: $title';

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Text(label),
        action: SnackBarAction(
          label: 'Nearby',
          onPressed: () => navCtx.go('/requests'),
        ),
      ),
    );
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
