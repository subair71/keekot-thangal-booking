import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/assignments/assignment_repository.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';

import 'fixtures.dart';

class _AssignedVisits implements AssignmentRepository {
  @override
  Stream<List<Record>> bookings(String? uid) => Stream.value([
    {
      'id': 'assigned-visit',
      'visitorName': 'Assigned Visitor',
      'bookingReference': 'KT-ASSIGNED',
      'visitDate': VisitClock.today(),
      'startTime': '10:00',
      'endTime': '10:12',
      'startAt': VisitClock.epoch(VisitClock.today(), '10:00'),
      'status': 'confirmed',
      'assignment': {
        'khadimId': uid,
        'displayName': 'Assigned Khadim',
        'status': 'assigned',
      },
    },
  ]);

  @override
  Stream<List<Record>> schedules(String? uid) => Stream.value([]);

  @override
  Stream<List<Record>> staff() => Stream.value([]);

  @override
  Future<Record> call(String name, Record data) => throw UnimplementedError();
}

Future<GoRouter> _openApp(WidgetTester tester, AppUser? user) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuth(user: user)),
        bookingRepositoryProvider.overrideWithValue(FakeBookings()),
        assignmentsRepositoryProvider.overrideWithValue(_AssignedVisits()),
      ],
      child: const KeekotApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(KeekotApp)),
  ).read(routerProvider);
}

void main() {
  for (final user in <AppUser?>[null, const AppUser('visitor', '')]) {
    testWidgets('Khadim scanner rejects ${user?.id ?? 'anonymous'}', (
      tester,
    ) async {
      final router = await _openApp(tester, user);
      router.go('/khadim/scan');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        user == null ? '/khadim/login' : '/access-denied',
      );
      if (user == null) {
        expect(
          router.routeInformationProvider.value.uri.queryParameters['next'],
          '/khadim/scan',
        );
      }
      expect(find.text('Scan and confirm visit'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('assigned Khadim opens scanner without global gate permission', (
    tester,
  ) async {
    const user = AppUser('khadim', '', khadim: true);
    final router = await _openApp(tester, user);
    router.go('/khadim');
    await tester.pumpAndSettle();
    expect(find.text('Assigned Visitor'), findsOneWidget);
    await tester.tap(find.text('Scan visitor pass'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/khadim/scan');
    expect(find.text('Scan and confirm visit'), findsOneWidget);
    expect(
      find.text(
        'Scan the QR code for a visit assigned to you. The pass must be within its allowed arrival and visit time.',
      ),
      findsOneWidget,
    );
    expect(user.can('gate'), isFalse);
    router.go('/admin/gate');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/access-denied');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khadim drawer opens visits and the assigned-pass scanner', (
    tester,
  ) async {
    final router = await _openApp(
      tester,
      const AppUser('khadim', '', khadim: true),
    );
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Your visits'));
    await tester.tap(find.text('Your visits'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/khadim');
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Validate visitor pass'));
    await tester.tap(find.text('Validate visitor pass'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/khadim/scan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer recognizes gate permission without a gate flag', (
    tester,
  ) async {
    const user = AppUser('permission-gate', '', permissions: ['gate']);
    expect(user.gate, isFalse);
    final router = await _openApp(tester, user);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Validate visitor pass'));
    await tester.tap(find.text('Validate visitor pass'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/gate');
    expect(find.text('Scan and confirm visit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final user in [
    const AppUser('admin', '', admin: true),
    const AppUser('gate', '', gate: true),
    const AppUser('khadim-gate', '', khadim: true, permissions: ['gate']),
  ]) {
    testWidgets('existing gate access remains available for ${user.id}', (
      tester,
    ) async {
      final router = await _openApp(tester, user);
      router.go('/admin/gate');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/admin/gate');
      expect(find.text('Scan and confirm visit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
