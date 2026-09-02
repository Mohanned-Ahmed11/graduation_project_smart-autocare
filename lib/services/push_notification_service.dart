import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/router/app_router.dart';

/// FCM deep links + token sync + Android 13+ notification permission.
class PushNotificationService {
  PushNotificationService._();

  static bool _deepLinksRegistered = false;

  static String? _stringData(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Call once after [Firebase.initializeApp] succeeds (e.g. from [main]).
  static void registerDeepLinks(GoRouter router) {
    if (_deepLinksRegistered) return;
    _deepLinksRegistered = true;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _openChatFromData(router, message.data);
    });

    // Foreground: system tray does not show by default — surface something in-app.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      final chatId = _stringData(message.data, 'chatId');
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            body.isNotEmpty ? '$title\n$body' : title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          action: chatId != null
              ? SnackBarAction(
                  label: 'Open',
                  onPressed: () => _openChatFromData(router, message.data),
                )
              : null,
        ),
      );
    });
  }

  /// Cold start / terminated: open chat from notification tap.
  static Future<void> handleInitialMessage(GoRouter router) async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openChatFromData(router, initial.data);
    });
  }

  static void _openChatFromData(GoRouter router, Map<String, dynamic> data) {
    final chatId = _stringData(data, 'chatId');
    if (chatId == null) return;
    final requestId = _stringData(data, 'requestId');
    final suffix =
        (requestId != null && requestId.isNotEmpty) ? '?requestId=$requestId' : '';
    router.go('/chat/$chatId$suffix');
  }

  static Future<void> syncTokenToProfile({
    required String userId,
    required Future<void> Function(String token) onSave,
  }) async {
    assert(userId.isNotEmpty);
    if (Firebase.apps.isEmpty) return;
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS || Platform.isMacOS) {
      await messaging.requestPermission();
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return;
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    await onSave(token);
  }
}
