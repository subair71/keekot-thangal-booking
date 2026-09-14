import 'dart:async';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';

const testConfig = BookingConfiguration(
  openingTime: '07:00',
  closingTime: '19:00',
  slotDurationMinutes: 30,
  bookingWindowDays: 7,
  allowSameDayBooking: true,
  maxVisitorsPerBooking: 6,
  defaultSlotCapacity: 12,
  bookingEnabled: true,
  reminderEnabled: true,
  reminderMinutes: 60,
  environment: 'development',
);

class FakeAuth implements AuthRepository {
  FakeAuth({this.user = const AppUser('visitor', '+919999999999')});
  final AppUser? user;
  bool sent = false;
  @override
  Stream<AppUser?> get userChanges => Stream.value(user);
  @override
  Future<void> sendCode(String phone) async {
    sent = true;
  }

  @override
  Future<void> verifyCode(String code) async {}
  @override
  Future<void> signOut() async {}
}

VisitBooking sampleBooking({String visitorName = 'Test Visitor'}) {
  final day = VisitClock.dayKey(VisitClock.now().add(const Duration(days: 1)));
  return VisitBooking(
    id: 'sample',
    reference: 'KT-20300110-012345ABCDEF',
    visitorName: visitorName,
    phoneMasked: '+91 ••••• 9999',
    visitDate: day,
    startTime: '10:00',
    endTime: '10:30',
    startAt: VisitClock.epoch(day, '10:00'),
    endAt: VisitClock.epoch(day, '10:30'),
    visitors: 2,
    status: 'confirmed',
    qrToken: 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG',
  );
}

class FakeBookings implements BookingRepository {
  FakeBookings({this.items = const []});
  final List<VisitBooking> items;
  @override
  Stream<BookingConfiguration> watchConfiguration() => Stream.value(testConfig);
  @override
  Stream<Set<String>> watchClosedDays() => Stream.value({});
  @override
  Future<Availability> availability(String day) async => Availability(
    const SlotGenerator().generate(day, testConfig),
    DateTime.now().millisecondsSinceEpoch,
  );
  @override
  Future<SlotHold?> activeHold() async {
    final b = sampleBooking(), now = DateTime.now().millisecondsSinceEpoch;
    return SlotHold(
      id: 'test-hold',
      slotId: '${b.visitDate}_1000',
      visitDate: b.visitDate,
      startTime: '10:00',
      endTime: '10:30',
      visitors: 2,
      expiresAt: now + 300000,
      serverNow: now,
    );
  }

  @override
  Future<SlotHold> createHold(
    VisitSlot slot,
    int visitors,
    String requestId,
  ) async => (await activeHold())!;
  @override
  Future<void> releaseHold(String id) async {}
  @override
  Future<String> confirm(String holdId, String name) async => 'sample';
  @override
  Stream<List<VisitBooking>> bookings(String uid) => Stream.value(items);
  @override
  Stream<VisitBooking?> booking(String id) => Stream.value(items.firstOrNull);
  @override
  Future<void> cancel(String id, String reason) async {}
}
