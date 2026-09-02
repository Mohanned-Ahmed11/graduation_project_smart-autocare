import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_providers.dart';
import '../services/push_notification_service.dart';

/// Writes FCM token to `profiles.fcm_token` when Firebase is configured and user signs in.
class PushTokenBootstrap extends ConsumerStatefulWidget {
  const PushTokenBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushTokenBootstrap> createState() => _PushTokenBootstrapState();
}

class _PushTokenBootstrapState extends ConsumerState<PushTokenBootstrap> {
  ProviderSubscription<AsyncValue<User?>>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    _authSub = ref.listenManual<AsyncValue<User?>>(authUserProvider, (prev, next) {
      next.whenData((user) async {
        if (user == null) {
          _lastSyncedUid = null;
          final sub = _tokenRefreshSub;
          _tokenRefreshSub = null;
          if (sub != null) unawaited(sub.cancel());
          return;
        }
        if (_lastSyncedUid == user.id) return;
        if (Firebase.apps.isEmpty) return;
        _lastSyncedUid = user.id;
        try {
          await PushNotificationService.syncTokenToProfile(
            userId: user.id,
            onSave: (token) async {
              await ref.read(supabaseClientProvider).from('profiles').update({
                'fcm_token': token,
              }).eq('id', user.id);
            },
          );
          _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
            (newToken) async {
              try {
                await ref.read(supabaseClientProvider).from('profiles').update({
                  'fcm_token': newToken,
                }).eq('id', user.id);
              } catch (_) {}
            },
          );
        } catch (_) {
          _lastSyncedUid = null;
        }
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _authSub?.close();
    final sub = _tokenRefreshSub;
    if (sub != null) unawaited(sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
