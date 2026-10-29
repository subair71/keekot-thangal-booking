import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/widgets/sanctuary_mobile_shell.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';

void main() {
  for (final user in <AppUser?>[
    null,
    const AppUser('visitor', ''),
    const AppUser('admin', '', admin: true),
    const AppUser('khadim', '', khadim: true),
    const AppUser('booking-khadim', '', khadim: true, permissions: ['bookings']),
    const AppUser('scanner-khadim', '', khadim: true, permissions: ['gate']),
    const AppUser('gate-khadim', '', khadim: true, gate: true),
  ]) {
    testWidgets('bottom navigation access for ${user?.id ?? 'guest'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          ShellRoute(
            builder: (_, _, child) => Scaffold(
              body: child,
              bottomNavigationBar: const SanctuaryMobileNavigation(),
            ),
            routes: [
              GoRoute(path: '/', builder: (_, _) => const SizedBox()),
              GoRoute(
                path: '/admin/gate',
                builder: (_, _) => const Text('Scanner destination'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => Stream.value(user))],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Heritage'), findsNothing);
      final scanner = find.byKey(
        const ValueKey('bottom-navigation-/admin/gate'),
      );
      final allowed =
          user?.admin == true ||
          (user?.khadim == true && user!.can('gate'));
      expect(scanner, allowed ? findsOneWidget : findsNothing);
      if (allowed) {
        expect(tester.getCenter(scanner).dx, closeTo(187.5, 1));
        await tester.tap(scanner);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/admin/gate');
        expect(find.text('Scanner destination'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
