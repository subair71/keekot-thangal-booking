import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';

import 'fixtures.dart';

void main() {
  test('return URL rejects external URLs and login loops', () {
    for (final url in [
      'https://example.com',
      '//example.com',
      '/admin/login',
      '/khadim/login?next=/admin',
      '/auth',
    ]) {
      expect(safeNext(url), '/my-bookings');
    }
    expect(safeNext('/booking/demo?tab=details'), '/booking/demo?tab=details');
  });
  for (final user in <AppUser?>[
    null,
    const AppUser('visitor', ''),
    const AppUser('khadim', '', khadim: true),
  ]) {
    testWidgets('role guards for ${user?.id ?? 'anonymous'}', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuth(user: user)),
            bookingRepositoryProvider.overrideWithValue(FakeBookings()),
          ],
          child: const KeekotApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KeekotApp)),
      );
      final router = container.read(routerProvider);
      router.go('/admin/assignments');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        user == null ? '/admin/login' : '/access-denied',
      );
      if (user == null) {
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
        expect(find.text('Send verification code'), findsNothing);
        expect(find.text('Send me a verification SMS'), findsNothing);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['next'],
          '/admin/assignments',
        );
        router.go('/khadim');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/khadim/login');
        router.go('/my-bookings');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
        expect(find.text('Send verification code'), findsOneWidget);
        expect(find.text('Username'), findsNothing);
        router.go('/auth');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
      }
      if (user?.khadim == true) {
        router.go('/book/confirmation');
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/access-denied',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
