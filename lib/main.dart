import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }
  try {
    await Firebase.initializeApp();
    PushNotificationService.registerDeepLinks(appRouter);
    await PushNotificationService.handleInitialMessage(appRouter);
  } catch (_) {
    // Firebase not configured (missing google-services / plist) — app runs without push.
  }
  runApp(const ProviderScope(child: SmartAutoCarApp()));
}
