class VisitNotice {
  const VisitNotice(this.id, this.title, this.body, this.bookingId, this.read);
  final String id, title, body, bookingId;
  final bool read;
}

abstract interface class NotificationRepository {
  Stream<List<VisitNotice>> notices(String uid);
  Stream<String> get foregroundMessages;
  Future<bool> enable();
  Future<void> disable();
  Future<void> markRead(String id);
  void dispose();
}
