import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'widgets/incoming_accept_listener.dart';
import 'widgets/incoming_offers_listener.dart';
import 'widgets/incoming_requests_listener.dart';
import 'widgets/push_token_bootstrap.dart';
import 'theme/app_theme.dart';
import 'providers/theme_mode_provider.dart';
import 'widgets/ambient_background.dart';
import 'widgets/premium_auto_geometrics.dart';

class SmartAutoCarApp extends ConsumerWidget {
  const SmartAutoCarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Smart Auto',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: appRouter,
      builder: (context, child) {
        return AmbientBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: PremiumAutoGeometrics(intensity: 0.72),
                ),
              ),
              PushTokenBootstrap(
                child: IncomingRequestsListener(
                  child: IncomingAcceptListener(
                    child: IncomingOffersListener(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
