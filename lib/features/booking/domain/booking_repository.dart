import 'booking_models.dart';

abstract interface class BookingRepository {
  Stream<BookingConfiguration> watchConfiguration();
  Stream<Set<String>> watchClosedDays();
  Future<Availability> availability(String day);
  Future<SlotHold?> activeHold();
  Future<SlotHold> createHold(VisitSlot slot, int visitors, String requestId);
  Future<void> releaseHold(String id);
  Future<String> confirm(String holdId, String name);
  Stream<List<VisitBooking>> bookings(String uid);
  Stream<VisitBooking?> booking(String id);
  Future<void> cancel(String id, String reason);
}
