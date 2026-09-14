import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/components.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/authentication/presentation/auth_page.dart';
import '../../features/booking/presentation/booking_page.dart';
import '../../features/booking/presentation/confirmation_page.dart';
import '../../features/my_bookings/presentation/my_bookings_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/visitor_information/presentation/information_page.dart';
import '../../features/admin/presentation/admin_page.dart';

class _AuthRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

String safeNext(String? next) {
  if (next == null ||
      !next.startsWith('/') ||
      next.startsWith('//') ||
      next.contains('://') ||
      next.startsWith('/auth')) {
    return '/my-bookings';
  }
  return next;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen(authProvider, (_, _) => refresh.refresh());
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authProvider).asData?.value, path = state.uri.path;
      final protected =
          path.startsWith('/admin') ||
          path == '/book/confirmation' ||
          path.startsWith('/book/success/') ||
          path == '/my-bookings' ||
          path.startsWith('/booking/') ||
          path.startsWith('/pass/') ||
          path == '/notifications';
      if (protected && user == null) {
        return '/auth?next=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (path.startsWith('/admin') &&
          user != null &&
          !user.admin &&
          !(path == '/admin/gate' && user.gate)) {
        return '/access-denied';
      }
      if (path == '/auth' && user != null) {
        return safeNext(state.uri.queryParameters['next']);
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomePage()),
          GoRoute(
            path: '/auth',
            builder: (_, s) =>
                AuthPage(next: safeNext(s.uri.queryParameters['next'])),
          ),
          GoRoute(path: '/book', builder: (_, _) => const BookingPage()),
          GoRoute(path: '/book/select-slot', redirect: (_, _) => '/book'),
          GoRoute(
            path: '/book/confirmation',
            builder: (_, _) => const ConfirmationPage(),
          ),
          GoRoute(
            path: '/book/success/:id',
            builder: (_, s) =>
                PassPage(id: s.pathParameters['id']!, success: true),
          ),
          GoRoute(
            path: '/my-bookings',
            builder: (_, _) => const MyBookingsPage(),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (_, s) => PassPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/pass/:id',
            builder: (_, s) => PassPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/information',
            builder: (_, _) => const InformationPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(path: '/admin', builder: (_, _) => const AdminPage()),
          for (final section in ['bookings', 'slots', 'settings', 'gate'])
            GoRoute(
              path: '/admin/$section',
              builder: (_, _) => AdminPage(section: section),
            ),
          GoRoute(
            path: '/access-denied',
            builder: (_, _) => const PageContainer(
              child: EmptyState(
                title: 'Staff access is required',
                detail: 'Use an authorized staff account to continue.',
              ),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, _) => Scaffold(
      body: PageContainer(
        child: EmptyState(
          title: 'This page could not be found',
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Return home'),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
