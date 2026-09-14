import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../features/authentication/data/firebase_auth_repository.dart';
import '../../features/authentication/domain/auth_repository.dart';
import '../../features/booking/data/firebase_booking_repository.dart';
import '../../features/booking/domain/booking_models.dart';
import '../../features/booking/domain/booking_repository.dart';
import '../../features/admin/data/firebase_admin_repository.dart';
import '../../features/admin/domain/admin_repository.dart';
import '../../features/notifications/data/firebase_notification_repository.dart';
import '../../features/notifications/domain/notification_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);
final firebaseBookingProvider = Provider(
  (ref) => FirebaseBookingRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: ref.watch(appConfigProvider).region),
  ),
);
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => ref.watch(firebaseBookingProvider),
);
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => FirebaseAdminRepository(ref.watch(firebaseBookingProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repo = FirebaseNotificationRepository(
    ref.watch(firebaseBookingProvider),
    FirebaseAuth.instance,
    ref.watch(appConfigProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});
final authProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges,
);
final configurationProvider = StreamProvider<BookingConfiguration>(
  (ref) => ref.watch(bookingRepositoryProvider).watchConfiguration(),
);
final closedDaysProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(bookingRepositoryProvider).watchClosedDays(),
);
final availabilityProvider = StreamProvider.autoDispose
    .family<Availability, String>((ref, day) {
      final repository = ref.watch(bookingRepositoryProvider);
      final controller = StreamController<Availability>();
      var disposed = false, refreshing = false;
      Future<void> refresh() async {
        if (disposed || refreshing) return;
        refreshing = true;
        try {
          final availability = await repository.availability(day);
          if (!disposed) controller.add(availability);
        } catch (error, stack) {
          if (!disposed) controller.addError(error, stack);
        } finally {
          refreshing = false;
        }
      }

      final timer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(refresh());
      });
      ref.onDispose(() {
        disposed = true;
        timer.cancel();
        unawaited(controller.close());
      });
      unawaited(refresh());
      return controller.stream;
    });
final myBookingsProvider = StreamProvider<List<VisitBooking>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  return user == null
      ? Stream.value([])
      : ref.watch(bookingRepositoryProvider).bookings(user.id);
});
final bookingProvider = StreamProvider.autoDispose
    .family<VisitBooking?, String>((ref, id) {
      final user = ref.watch(authProvider).asData?.value;
      return user == null
          ? Stream.value(null)
          : ref.watch(bookingRepositoryProvider).booking(id);
    });
final noticesProvider = StreamProvider<List<VisitNotice>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  return user == null
      ? Stream.value([])
      : ref.watch(notificationRepositoryProvider).notices(user.id);
});
final adminDashboardProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);
final adminBookingsProvider = StreamProvider.autoDispose
    .family<List<VisitBooking>, String>(
      (ref, day) => ref.watch(adminRepositoryProvider).bookingsForDate(day),
    );

class BookingDraft {
  const BookingDraft({this.slot, this.visitors = 1, this.requestId = ''});
  final VisitSlot? slot;
  final int visitors;
  final String requestId;
}

class DraftController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();
  void select(VisitSlot slot, int visitors) {
    final random = Random.secure();
    state = BookingDraft(
      slot: slot,
      visitors: visitors,
      requestId: List.generate(
        24,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );
  }

  void clear() => state = const BookingDraft();
}

final draftProvider = NotifierProvider<DraftController, BookingDraft>(
  DraftController.new,
);

final foregroundMessagesProvider = StreamProvider<String>(
  (ref) => ref.watch(notificationRepositoryProvider).foregroundMessages,
);
