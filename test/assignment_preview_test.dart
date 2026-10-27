import 'package:intl/date_symbol_data_local.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/assignments/assignment_pages.dart';
import 'package:keekot_thangal/features/assignments/assignment_repository.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/authentication/presentation/auth_page.dart';
import 'package:keekot_thangal/features/admin/presentation/khadim_page.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/booking/presentation/booking_page.dart';
import 'package:keekot_thangal/features/home/presentation/home_page.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/pass_card.dart';

import 'fixtures.dart';
import 'widget_test.dart' show captureKey, capturePage;

class DemoAssignments implements AssignmentRepository {
  final day = VisitClock.today();
  List<Record> get visits => [
    for (var i = 0; i < 4; i++)
      {
        'id': 'demo-$i',
        'userId': 'demo-visitor',
        'visitorName': [
          'DEMO · Ameen',
          'DEMO · Haneef',
          'DEMO · Yusuf',
          'DEMO · Faris',
        ][i],
        'bookingReference': 'DEMO-KT-00${i + 1}',
        'tokenStart': i + 1,
        'visitDate': day,
        'startTime': '10:${(i * 12).toString().padLeft(2, '0')}',
        'endTime': '10:${((i + 1) * 12).toString().padLeft(2, '0')}',
        'startAt': VisitClock.epoch(day, '10:00') + i * 720000,
        'endAt': VisitClock.epoch(day, '10:12') + i * 720000,
        'status': 'confirmed',
        if (i != 0)
          'assignment': {
            'khadimId': 'demo-khadim',
            'displayName': 'DEMO · Abdullah',
            'status': i == 1
                ? 'assigned'
                : i == 2
                ? 'inProgress'
                : 'completed',
            'revision': 1,
          },
      },
  ];
  @override
  Stream<List<Record>> bookings(String? uid) => Stream.value(
    visits
        .where(
          (b) => uid == null || (b['assignment'] as Map?)?['khadimId'] == uid,
        )
        .toList(),
  );
  @override
  Stream<List<Record>> schedules(String? uid) => Stream.value([
    {
      'id': 'demo-schedule',
      'khadimId': 'demo-khadim',
      'visitDate': day,
      'hours': [
        {'start': '07:00', 'end': '19:00'},
      ],
      'breaks': [
        {'start': '12:30', 'end': '13:00'},
      ],
      'available': true,
      'capacity': 1,
    },
  ]);
  @override
  Stream<List<Record>> staff() => Stream.value([
    {'id': 'demo-khadim', 'name': 'DEMO · Abdullah'},
    {'id': 'demo-other', 'name': 'DEMO · Ibrahim'},
  ]);
  @override
  Future<Record> call(String name, Record data) async => {
    'candidates': [
      {
        'uid': 'demo-khadim',
        'name': 'DEMO · Abdullah',
        'eligible': true,
        'state': 'Available',
        'reason': '',
        'workload': 0,
        'capacity': 1,
      },
      {
        'uid': 'demo-other',
        'name': 'DEMO · Ibrahim',
        'eligible': false,
        'state': 'Busy',
        'reason': 'Capacity is full',
        'workload': 1,
        'capacity': 1,
      },
      {
        'uid': 'demo-off',
        'name': 'DEMO · Hamza',
        'eligible': false,
        'state': 'Off duty',
        'reason': 'No working schedule configured',
        'workload': 0,
        'capacity': 1,
      },
    ],
  };
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    for (final font in {
      'Playfair Display': 'PlayfairDisplay.ttf',
      'Plus Jakarta Sans': 'PlusJakartaSans.ttf',
      'Noto Sans Malayalam': 'NotoSansMalayalam.ttf',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [390, 1440]) {
    for (final screen in [
      'home',
      'booking',
      'visitor-login',
      'admin-login',
      'khadim-login',
      'assignments',
      'availability',
      'assign-dialog',
      'reassign-dialog',
      'khadim-dashboard',
      'khadim-availability',
      'visitor-pass',
      'assignments-ml',
      'availability-ml',
      'admin-login-ml',
      'khadim-login-ml',
    ]) {
      testWidgets('DEMO $screen ${width}px', (tester) async {
        tester.view.physicalSize = Size(width.toDouble(), 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = DemoAssignments();
        final language = screen.endsWith('-ml') ? 'ml' : 'en';
        final screenKind = screen.replaceAll('-ml', '');
        Widget page = switch (screenKind) {
          'home' => const HomePage(),
          'booking' => const BookingPage(),
          'visitor-login' => const AuthPage(),
          'admin-login' => const AuthPage(admin: true),
          'khadim-login' => const KhadimLoginPage(),
          'assignments' => const AssignmentPage(),
          'availability' => const AvailabilityPage(),
          'assign-dialog' => const AssignmentPage(),
          'reassign-dialog' => const AssignmentPage(),
          'khadim-dashboard' => const AssignmentPage(staff: true),
          'khadim-availability' => const AvailabilityPage(staff: true),
          _ => SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 620,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PassCard(
                    booking: VisitBooking(
                      id: 'demo',
                      reference: 'DEMO-KT-002',
                      visitorName: 'DEMO · Haneef',
                      phoneMasked: '+91 ••••• 0000',
                      visitDate: repo.day,
                      startTime: '10:12',
                      endTime: '10:24',
                      startAt: VisitClock.epoch(repo.day, '10:12'),
                      endAt: VisitClock.epoch(repo.day, '10:24'),
                      visitors: 1,
                      status: 'confirmed',
                      qrToken: 'DEMO-NOT-A-VALID-PASS',
                      khadimName: 'DEMO · Abdullah',
                      serviceStatus: 'assigned',
                    ),
                  ),
                ),
              ),
            ),
          ),
        };
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(
                  FakeAuth(
                    user:
                        (screen == 'khadim-dashboard' ||
                            screen == 'khadim-availability')
                        ? const AppUser('demo-khadim', '', khadim: true)
                        : screen.contains('login')
                        ? null
                        : const AppUser('demo-admin', '', admin: true),
                  ),
                ),
                bookingRepositoryProvider.overrideWithValue(FakeBookings()),
                assignmentsRepositoryProvider.overrideWithValue(repo),
              ],
              child: AppLanguage(
                notifier: ValueNotifier(language),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: language == 'ml'
                      ? buildTheme().copyWith(
                          textTheme: buildTheme().textTheme.apply(
                            fontFamily: 'Noto Sans Malayalam',
                          ),
                        )
                      : buildTheme(),
                  home: Scaffold(
                    appBar: AppBar(
                      title: const Text('DEMO PREVIEW · No production data'),
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                    ),
                    body: page,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (screenKind == 'assign-dialog' || screenKind == 'reassign-dialog') {
          unawaited(
            showDialog<void>(
              context: tester.element(find.byType(AssignmentPage)),
              builder: (_) => AssignDialog(
                booking: repo.visits[screenKind == 'assign-dialog' ? 0 : 1],
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(OutlinedButton, 'DEMO · Abdullah').last,
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await capturePage(tester, 'premium-$screen-$width');
        if (screenKind == 'availability') {
          await tester.ensureVisible(
            find
                .text(
                  tr(
                    tester.element(find.byType(AvailabilityPage)),
                    'Edit schedule',
                  ),
                )
                .last,
          );
          await tester.pumpAndSettle();
          await capturePage(tester, 'premium-$screen-current-$width');
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
