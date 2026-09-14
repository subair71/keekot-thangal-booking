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
  Future<void> updateSlots(Map<String, dynamic> change) async {
    await source.call('adminUpdateSlot', change);
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await source.call('adminUpdateSettings', settings);
  }

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
