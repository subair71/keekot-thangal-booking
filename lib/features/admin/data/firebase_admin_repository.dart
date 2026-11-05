import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../../notifications/domain/home_notice.dart';

import '../../booking/data/firebase_booking_repository.dart';
import '../../booking/domain/booking_models.dart';
import '../domain/admin_repository.dart';

class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository(this.source);
  final FirebaseBookingRepository source;
  @override
  Future<Map<String, int>> dashboard() async => (await source.call(
    'adminDashboard',
    {},
  )).map((k, v) => MapEntry(k, (v as num).toInt()));
  @override
  Stream<List<VisitBooking>> bookingsForDate(String date) => source.db
      .collection('bookings')
      .where('visitDate', isEqualTo: date)
      .orderBy('startAt')
      .snapshots()
      .map((s) => s.docs.map((d) => VisitBooking.fromMap(d.data())).toList());
  @override
  Future<List<VisitBooking>> exportBookingsForDate(String date) async {
    var snapshot = await source.db
        .collection('bookings')
        .where('visitDate', isEqualTo: date)
        .get(const GetOptions(source: Source.server));
    final slots = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['tokenStart'] == null || data['tokenEnd'] == null) &&
          slots.add(data['slotId'] as String)) {
        final tokens = await source.ensureTokens(doc.id);
        if (tokens == null) {
          throw StateError(
            'Could not prepare booking tokens for export. Please retry.',
          );
        }
      }
    }
    if (slots.isNotEmpty) {
      snapshot = await source.db
          .collection('bookings')
          .where('visitDate', isEqualTo: date)
          .get(const GetOptions(source: Source.server));
    }
    return snapshot.docs.map((d) => VisitBooking.fromMap(d.data())).toList();
  }

  @override
  Future<void> updateSlots(Map<String, dynamic> change) async {
    await source.call('adminUpdateSlot', change);
  }

  @override
  Future<void> setDateHours(Map<String, dynamic> change) async {
    await source.call('adminSetDateHours', change);
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await source.call('adminUpdateSettings', settings);
  }

  String noticeAuthor() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw const AppFailure('Sign in to continue.');
    return uid;
  }

  @override
  Future<void> publishHomeNotice(HomeNotice notice) => protect(() async {
    final text = notice.reason.trim();
    if (text.isEmpty || text.length > 500) {
      throw const AppFailure('Enter a notice of up to 500 characters.');
    }
    await source.db.doc('settings/booking').update({
      'homeNotice': {
        'visitDate': notice.visitDate,
        'reason': text,
        'active': true,
        'updatedBy': noticeAuthor(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  });

  @override
  Future<void> hideHomeNotice() => protect(() async {
    await source.db.doc('settings/booking').update({
      'homeNotice.active': false,
      'homeNotice.updatedBy': noticeAuthor(),
      'homeNotice.updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> setBookingStatus(String id, String status) async {
    await source.call('adminSetBookingStatus', {
      'bookingId': id,
      'status': status,
    });
  }

  @override
  Future<Map<String, dynamic>> validatePass(String token, bool checkIn) =>
      source.call('validatePass', {'qrToken': token, 'checkIn': checkIn});
}
