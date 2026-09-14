import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../domain/booking_models.dart';
import '../domain/booking_repository.dart';

class FirebaseBookingRepository implements BookingRepository {
  FirebaseBookingRepository(this.db, this.functions);
  final FirebaseFirestore db;
  final FirebaseFunctions functions;
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) =>
      protect(() async {
        final result = await functions.httpsCallable(name).call<dynamic>(data);
        return Map<String, dynamic>.from(result.data as Map);
      });
  @override
  Stream<BookingConfiguration> watchConfiguration() =>
      db.doc('settings/booking').snapshots().map((doc) {
        if (!doc.exists)
          throw const AppFailure(
            'Visits are not open for booking yet. Please check again soon.',
          );
        return BookingConfiguration.fromMap(doc.data()!);
      });
  @override
  Stream<Set<String>> watchClosedDays() => db
      .collection('closures')
      .where('closed', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
  @override
  Future<Availability> availability(String day) async =>
      Availability.fromMap(await call('getAvailability', {'visitDate': day}));
  @override
  Future<SlotHold?> activeHold() async {
    final data = await call('getActiveHold', {});
    return data['hold'] == null
        ? null
        : SlotHold.fromMap(Map<String, dynamic>.from(data['hold'] as Map));
  }

  @override
  Future<SlotHold> createHold(
    VisitSlot slot,
    int visitors,
    String requestId,
  ) async => SlotHold.fromMap(
    await call('createHold', {
      'visitDate': slot.visitDate,
      'slotId': slot.id,
      'visitorCount': visitors,
      'requestId': requestId,
    }),
  );
  @override
  Future<void> releaseHold(String id) async {
    await call('releaseHold', {'holdId': id});
  }

  @override
  Future<String> confirm(String holdId, String name) async =>
      (await call('createBooking', {
            'holdId': holdId,
            'visitorName': name,
          }))['bookingId']
          as String;
  @override
  Stream<List<VisitBooking>> bookings(String uid) => db
      .collection('bookings')
      .where('userId', isEqualTo: uid)
      .orderBy('startAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => VisitBooking.fromMap(d.data())).toList());
  @override
  Stream<VisitBooking?> booking(String id) => db
      .doc('bookings/$id')
      .snapshots()
      .map((d) => d.exists ? VisitBooking.fromMap(d.data()!) : null);
  @override
  Future<void> cancel(String id, String reason) async {
    await call('cancelBooking', {'bookingId': id, 'reason': reason});
  }
}
