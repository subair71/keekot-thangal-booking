// Isolated design preview. All booking state stays in this browser session.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/errors/app_failure.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/notifications/domain/notification_repository.dart';

import '../test/fixtures.dart';

class PreviewAuth implements AuthRepository {
  AppUser? _user = const AppUser('preview-visitor', '+919999999999');
  final _updates = StreamController<AppUser?>.broadcast();
  @override
  Stream<AppUser?> get userChanges async* {
    yield _user;
    yield* _updates.stream;
  }

  @override
  Future<void> sendCode(String phone) async => throw const AppFailure(
    'This is a design preview. Refresh the page to restore the sample visitor session.',
  );
  @override
  Future<void> verifyCode(String code) async {}
  @override
  Future<void> signOut() async {
    _user = null;
    _updates.add(null);
  }
}

class PreviewBookings extends FakeBookings {
  SlotHold? _hold;
  final _records = <String, Map<String, dynamic>>{};
  final _updates = StreamController<void>.broadcast();
  int _sequence = 0;
  @override
  Future<SlotHold?> activeHold() async => _hold;
  @override
  Future<SlotHold> createHold(
    VisitSlot slot,
    int visitors,
    String requestId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _hold = SlotHold(
      id: 'preview-hold',
      slotId: slot.id,
      visitDate: slot.visitDate,
      startTime: slot.startTime,
      endTime: slot.endTime,
      visitors: visitors,
      expiresAt: now + 300000,
      serverNow: now,
    );
  }

  @override
  Future<void> releaseHold(String id) async {
    _hold = null;
  }

  @override
  Future<String> confirm(
    String holdId,
    String name,
    String address, {
    String? visitorPhone,
  }) async {
    final hold = _hold;
    if (hold == null) throw StateError('Select a preview time first.');
    final id = 'preview-${++_sequence}';
    _records[id] = {
      'bookingId': id,
      'bookingReference': 'PREVIEW-${_sequence.toString().padLeft(4, '0')}',
      'visitorName': name,
      'visitorAddress': address,
      'visitorPhone': visitorPhone ?? '+919999999999',
      'phoneNumberMasked': '+91 ••••• 9999',
      'visitDate': hold.visitDate,
      'startTime': hold.startTime,
      'endTime': hold.endTime,
      'startAt': VisitClock.epoch(hold.visitDate, hold.startTime),
      'endAt': VisitClock.epoch(hold.visitDate, hold.endTime),
      'visitorCount': hold.visitors,
      'status': 'confirmed',
      'qrToken': 'preview-only-not-a-valid-entry-pass',
    };
    _hold = null;
    _updates.add(null);
    return id;
  }

  @override
  Stream<List<VisitBooking>> bookings(String uid) async* {
    yield _records.values.map(VisitBooking.fromMap).toList();
    await for (final _ in _updates.stream) {
      yield _records.values.map(VisitBooking.fromMap).toList();
    }
  }

  @override
  Stream<VisitBooking?> booking(String id) async* {
    yield _records.containsKey(id) ? VisitBooking.fromMap(_records[id]!) : null;
    await for (final _ in _updates.stream) {
      yield _records.containsKey(id)
          ? VisitBooking.fromMap(_records[id]!)
          : null;
    }
  }

  @override
  Future<void> cancel(String id, String reason) async {
    if (_records.containsKey(id)) _records[id]!['status'] = 'cancelled';
    _updates.add(null);
  }
}

class PreviewNotifications implements NotificationRepository {
  @override
  Stream<List<VisitNotice>> notices(String uid) => Stream.value([]);
  @override
  Stream<String> get foregroundMessages => const Stream.empty();
  @override
  Future<bool> enable() async => false;
  @override
  Future<void> disable() async {}
  @override
  Future<void> markRead(String id) async {}
  @override
  void dispose() {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(PreviewAuth()),
        bookingRepositoryProvider.overrideWithValue(PreviewBookings()),
        notificationRepositoryProvider.overrideWithValue(
          PreviewNotifications(),
        ),
      ],
      child: const KeekotApp(),
    ),
  );
}
