import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_detection/ai_detection_screen.dart';
import '../../features/ai_detection/ai_result_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/nearby_services_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/requests/create_request_screen.dart';
import '../../features/requests/my_requests_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../models/issue_model.dart';
import '../../widgets/main_shell_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// SnackBars from realtime listeners (no local Scaffold).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/requests',
              name: 'requests',
              builder: (context, state) => const RequestsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/requests/mine',
              name: 'requests-mine',
              builder: (context, state) => const MyRequestsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/ai-detection',
      name: 'ai-detection',
      builder: (context, state) => AiDetectionScreen(
        initialMode: state.uri.queryParameters['mode'],
      ),
    ),
    GoRoute(
      path: '/ai-result',
      name: 'ai-result',
      builder: (context, state) {
        final issue = state.extra as IssueModel?;
        return AiResultScreen(issue: issue);
      },
    ),
    GoRoute(
      path: '/nearby-services',
      name: 'nearby-services',
      builder: (context, state) => const NearbyServicesScreen(),
    ),
    GoRoute(
      path: '/request/new',
      name: 'request-new',
      builder: (context, state) => const CreateRequestScreen(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      name: 'chat',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final requestId = state.uri.queryParameters['requestId'];
        return ChatScreen(chatId: chatId, requestId: requestId);
      },
    ),
  ],
);
