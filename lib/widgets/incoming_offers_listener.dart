import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/router/app_router.dart';
import '../providers/app_providers.dart';
import '../providers/my_requests_provider.dart';
import '../providers/open_requests_provider.dart';
import 'incoming_offer_notification.dart';

/// Subscribes to `request_responses` inserts and notifies the requester in-app.
class IncomingOffersListener extends ConsumerStatefulWidget {
  const IncomingOffersListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingOffersListener> createState() => _IncomingOffersListenerState();
}

class _IncomingOffersListenerState extends ConsumerState<IncomingOffersListener> {
  RealtimeChannel? _channel;
  String? _boundUserId;
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  @override
  void initState() {
    super.initState();
    // ref.listen only works during build; listenManual is valid here.
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
    _channel = client.channel('requester_offers_$userId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request_responses',
          callback: (payload) => _onInsert(userId, payload),
        )
        .subscribe();
  }

  Future<void> _onInsert(String userId, PostgresChangePayload payload) async {
    final row = payload.newRecord;
    if (row['status']?.toString() != 'pending') return;
    final requestId = row['request_id']?.toString();
    if (requestId == null) return;

    final client = ref.read(supabaseClientProvider);
    final req = await client.from('requests').select('user_id, title').eq('id', requestId).maybeSingle();
    if (req == null || req['user_id'] != userId) return;
    if (!mounted) return;

    ref.invalidate(openRequestsProvider);
    ref.invalidate(requestsFeedProvider);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(myRequestPendingCountsProvider);

    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;
    final title = (req['title'] as String?)?.trim() ?? '';
    await showIncomingOfferDialog(navCtx, requestTitle: title);
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
