import '../../../core/utils/visit_clock.dart';

class BookingConfiguration {
  const BookingConfiguration({
    required this.openingTime,
    required this.closingTime,
    required this.slotDurationMinutes,
    required this.bookingWindowDays,
    required this.allowSameDayBooking,
    required this.maxVisitorsPerBooking,
    required this.defaultSlotCapacity,
    required this.bookingEnabled,
    required this.reminderEnabled,
    required this.reminderMinutes,
    this.arrivalMinutes = 10,
    this.locationUrl = '',
    this.contactPhone = '',
    this.environment = 'production',
  });
  final String openingTime, closingTime, locationUrl, contactPhone, environment;
  final int slotDurationMinutes,
      bookingWindowDays,
      maxVisitorsPerBooking,
      defaultSlotCapacity,
      reminderMinutes,
      arrivalMinutes;
  final bool allowSameDayBooking, bookingEnabled, reminderEnabled;
  factory BookingConfiguration.fromMap(Map<String, dynamic> m) =>
      BookingConfiguration(
        openingTime: m['openingTime'] as String,
        closingTime: m['closingTime'] as String,
        slotDurationMinutes: (m['slotDurationMinutes'] as num).toInt(),
        bookingWindowDays: (m['bookingWindowDays'] as num).toInt(),
        allowSameDayBooking: m['allowSameDayBooking'] == true,
        maxVisitorsPerBooking: (m['maxVisitorsPerBooking'] as num).toInt(),
        defaultSlotCapacity: (m['defaultSlotCapacity'] as num).toInt(),
        bookingEnabled: m['bookingEnabled'] == true,
        reminderEnabled: m['reminderEnabled'] == true,
        reminderMinutes: (m['reminderMinutes'] as num).toInt(),
        arrivalMinutes: (m['arrivalMinutes'] as num?)?.toInt() ?? 10,
        locationUrl: m['locationUrl'] as String? ?? '',
        contactPhone: m['contactPhone'] as String? ?? '',
        environment: m['environment'] as String? ?? 'production',
      );
  Map<String, dynamic> toMap() => {
    'timezone': 'Asia/Kolkata',
    'openingTime': openingTime,
    'closingTime': closingTime,
    'slotDurationMinutes': slotDurationMinutes,
    'bookingWindowDays': bookingWindowDays,
    'allowSameDayBooking': allowSameDayBooking,
    'maxVisitorsPerBooking': maxVisitorsPerBooking,
    'defaultSlotCapacity': defaultSlotCapacity,
    'bookingEnabled': bookingEnabled,
    'reminderEnabled': reminderEnabled,
    'reminderMinutes': reminderMinutes,
    'arrivalMinutes': arrivalMinutes,
    'locationUrl': locationUrl,
    'contactPhone': contactPhone,
  };
  List<String> dates([DateTime? clock]) {
    final n = clock ?? VisitClock.now();
    final today = DateTime.utc(n.year, n.month, n.day);
    return [
      for (var i = allowSameDayBooking ? 0 : 1; i < bookingWindowDays; i++)
        VisitClock.dayKey(today.add(Duration(days: i))),
    ];
  }

  String get hours =>
      '${VisitClock.timeLabel(openingTime)} – ${VisitClock.timeLabel(closingTime)}';
}

enum SlotStatus { available, full, blocked, past }

class VisitSlot {
  const VisitSlot({
    required this.id,
    required this.visitDate,
    required this.startTime,
    required this.endTime,
    required this.startAt,
    required this.endAt,
    required this.remaining,
    required this.capacity,
    required this.status,
    this.reason = '',
  });
  final String id, visitDate, startTime, endTime, reason;
  final int startAt, endAt, remaining, capacity;
  final SlotStatus status;
  factory VisitSlot.fromMap(Map<String, dynamic> m) => VisitSlot(
    id: m['slotId'] as String,
    visitDate: m['visitDate'] as String,
    startTime: m['startTime'] as String,
    endTime: m['endTime'] as String,
    startAt: (m['startAt'] as num).toInt(),
    endAt: (m['endAt'] as num).toInt(),
    remaining: (m['remaining'] as num).toInt(),
    capacity: (m['capacity'] as num).toInt(),
    status: SlotStatus.values.byName(m['status'] as String),
    reason: m['blockReason'] as String? ?? '',
  );
  String get label =>
      '${VisitClock.timeLabel(startTime)} – ${VisitClock.timeLabel(endTime)}';
  bool accepts(int count) =>
      status == SlotStatus.available && count > 0 && count <= remaining;
}

class Availability {
  const Availability(
    this.slots,
    this.serverNow, {
    this.closed = false,
    this.reason = '',
  });
  final List<VisitSlot> slots;
  final int serverNow;
  final bool closed;
  final String reason;
  factory Availability.fromMap(Map<String, dynamic> m) => Availability(
    (m['slots'] as List)
        .map((x) => VisitSlot.fromMap(Map<String, dynamic>.from(x as Map)))
        .toList(),
    (m['serverNow'] as num).toInt(),
    closed: m['closed'] == true,
    reason: m['reason'] as String? ?? '',
  );
}

class SlotHold {
  const SlotHold({
    required this.id,
    required this.slotId,
    required this.visitDate,
    required this.startTime,
    required this.endTime,
    required this.visitors,
    required this.expiresAt,
    required this.serverNow,
  });
  final String id, slotId, visitDate, startTime, endTime;
  final int visitors, expiresAt, serverNow;
  factory SlotHold.fromMap(Map<String, dynamic> m) => SlotHold(
    id: m['holdId'] as String,
    slotId: m['slotId'] as String,
    visitDate: m['visitDate'] as String,
    startTime: m['startTime'] as String,
    endTime: m['endTime'] as String,
    visitors: (m['visitorCount'] as num).toInt(),
    expiresAt: (m['expiresAt'] as num).toInt(),
    serverNow: (m['serverNow'] as num).toInt(),
  );
  String get label =>
      '${VisitClock.timeLabel(startTime)} – ${VisitClock.timeLabel(endTime)}';
}

class VisitBooking {
  const VisitBooking({
    required this.id,
    required this.reference,
    required this.visitorName,
    required this.phoneMasked,
    required this.visitDate,
    required this.startTime,
    required this.endTime,
    required this.startAt,
    required this.endAt,
    required this.visitors,
    required this.status,
    required this.qrToken,
  });
  final String id,
      reference,
      visitorName,
      phoneMasked,
      visitDate,
      startTime,
      endTime,
      status,
      qrToken;
  final int startAt, endAt, visitors;
  factory VisitBooking.fromMap(Map<String, dynamic> m) => VisitBooking(
    id: m['bookingId'] as String,
    reference: m['bookingReference'] as String,
    visitorName: m['visitorName'] as String,
    phoneMasked: m['phoneNumberMasked'] as String? ?? '',
    visitDate: m['visitDate'] as String,
    startTime: m['startTime'] as String,
    endTime: m['endTime'] as String,
    startAt: (m['startAt'] as num).toInt(),
    endAt: (m['endAt'] as num).toInt(),
    visitors: (m['visitorCount'] as num).toInt(),
    status: m['status'] as String,
    qrToken: m['qrToken'] as String,
  );
  String get timeLabel =>
      '${VisitClock.timeLabel(startTime)} – ${VisitClock.timeLabel(endTime)}';
  bool get upcoming =>
      status == 'confirmed' && endAt > DateTime.now().millisecondsSinceEpoch;
  bool get canCancel =>
      status == 'confirmed' && startAt > DateTime.now().millisecondsSinceEpoch;
}

/// Generates complete half-hour (or configured duration) periods in India time.
class SlotGenerator {
  const SlotGenerator();
  List<VisitSlot> generate(String day, BookingConfiguration c) {
    int mins(String t) {
      final p = t.split(':').map(int.parse).toList();
      return p[0] * 60 + p[1];
    }

    String time(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    final out = <VisitSlot>[];
    if (c.slotDurationMinutes <= 0)
      throw ArgumentError('Slot duration must be positive.');
    for (
      var m = mins(c.openingTime);
      m + c.slotDurationMinutes <= mins(c.closingTime);
      m += c.slotDurationMinutes
    ) {
      final start = time(m), end = time(m + c.slotDurationMinutes);
      out.add(
        VisitSlot(
          id: '${day}_${start.replaceAll(':', '')}',
          visitDate: day,
          startTime: start,
          endTime: end,
          startAt: VisitClock.epoch(day, start),
          endAt: VisitClock.epoch(day, end),
          remaining: c.defaultSlotCapacity,
          capacity: c.defaultSlotCapacity,
          status: SlotStatus.available,
        ),
      );
    }
    return out;
  }
}
