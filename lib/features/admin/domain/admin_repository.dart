import '../../booking/domain/booking_models.dart';

abstract interface class AdminRepository {
  Future<Map<String, int>> dashboard();
  Stream<List<VisitBooking>> bookingsForDate(String date);
  Future<void> updateSlots(Map<String, dynamic> change);
  Future<void> updateSettings(Map<String, dynamic> settings);
  Future<void> setBookingStatus(String id, String status);
  Future<Map<String, dynamic>> validatePass(String token, bool checkIn);
}
