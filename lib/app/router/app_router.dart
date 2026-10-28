import '../../core/localization/app_language.dart';
import '../../features/assignments/assignment_pages.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/components.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/contact/presentation/contact_page.dart';
import '../../features/authentication/presentation/auth_page.dart';
import '../../features/booking/presentation/booking_page.dart';
import '../../features/booking/presentation/confirmation_page.dart';
import '../../features/my_bookings/presentation/my_bookings_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/visitor_information/presentation/information_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/admin/presentation/khadim_page.dart';

class _AuthRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

String safeNext(String? next) {
  if (next == null ||
      !next.startsWith('/') ||
      next.startsWith('//') ||
      next.contains('://') ||
      next.startsWith('/auth') ||
      next.split('?').first.endsWith('/login') ||
      next.startsWith('/khadim-login')) {
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
      final login = ['/login', '/admin/login', '/khadim/login'].contains(path);
      if (path == '/auth') {
        return '/login${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
      }
      if (path == '/khadim-login') {
        return '/khadim/login${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
      }
      if (login) {
        if (user == null) return null;
        if (path == '/admin/login' && !user.admin) return '/access-denied';
        if (path == '/khadim/login' && !user.khadim) return '/access-denied';
        final next = state.uri.queryParameters['next'];
        return next == null
            ? (user.admin
                  ? '/admin'
                  : user.khadim
                  ? '/khadim'
                  : '/my-bookings')
            : safeNext(next);
      }
      final protected =
          path.startsWith('/admin') ||
          path.startsWith('/khadim') ||
          path == '/book/confirmation' ||
          path.startsWith('/book/success/') ||
          path == '/my-bookings' ||
          path.startsWith('/booking/') ||
          path == '/notifications';
      if (protected && user == null) {
        final entry = path.startsWith('/admin')
            ? '/admin/login'
            : path.startsWith('/khadim')
            ? '/khadim/login'
            : '/login';
        return '$entry?next=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (path.startsWith('/khadim') && user?.khadim != true) {
        return '/access-denied';
      }
      if (path == '/book/confirmation' &&
          user != null &&
          user.khadim &&
          !user.canBookForVisitor) {
        return '/access-denied';
      }
      if (path.startsWith('/admin') && user != null) {
        final section = path == '/admin' ? 'dashboard' : path.split('/').last;
        if ([
              'khadims',
              'assignments',
              'availability',
              'bookings',
              'dashboard',
            ].contains(section) &&
            !user.admin) {
          return '/access-denied';
        }
        if (!['khadims', 'assignments', 'availability'].contains(section) &&
            !user.can(section)) {
          return '/access-denied';
        }
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, state) =>
                HomePage(section: state.uri.queryParameters['section']),
          ),
          GoRoute(
            path: '/khadim/login',
            builder: (_, _) => const KhadimLoginPage(),
          ),
          GoRoute(
            path: '/admin/khadims',
            builder: (_, _) => const KhadimManagementPage(),
          ),
          GoRoute(
            path: '/auth',
            redirect: (_, s) =>
                '/login${s.uri.hasQuery ? '?${s.uri.query}' : ''}',
          ),
          GoRoute(path: '/khadim-login', redirect: (_, _) => '/khadim/login'),
          GoRoute(
            path: '/admin/login',
            builder: (_, s) => AuthPage(
              admin: true,
              next: safeNext(s.uri.queryParameters['next'] ?? '/admin'),
            ),
          ),
          GoRoute(
            path: '/admin/assignments',
            builder: (_, _) => const AssignmentPage(),
          ),
          GoRoute(
            path: '/admin/availability',
            builder: (_, _) => const AvailabilityPage(),
          ),
          GoRoute(
            path: '/khadim',
            builder: (_, _) => const AssignmentPage(staff: true),
          ),
          GoRoute(
            path: '/khadim/availability',
            builder: (_, _) => const AvailabilityPage(staff: true),
          ),
          GoRoute(path: '/contact', builder: (_, _) => const ContactPage()),
          GoRoute(
            path: '/login',
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
      appBar: AppBar(title: const AppText('Page not found')),
      body: PageContainer(
        child: EmptyState(
          title: 'This page could not be found',
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const AppText('Return home'),
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
