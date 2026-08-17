import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/notifications/presentation/screens/notifications_settings_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/reports/presentation/screens/home_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';

/// Se reconstruye cada vez que cambia `authControllerProvider` — suficiente
/// para una app de este tamaño; evita el boilerplate de un Listenable/stream
/// bridge solo para el `redirect` de go_router.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/reports/new',
        builder: (context, state) => const CreateReportScreen(),
      ),
      GoRoute(
        path: '/reports/:id',
        builder: (context, state) => ReportDetailScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatInboxScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(conversationId: state.pathParameters['id']!),
      ),
    ],
  );
});
