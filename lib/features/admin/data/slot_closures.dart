import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../booking/domain/booking_models.dart';

final adminScheduleClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Read saved closures directly so staff can manage the full 30-day range,
/// including dates outside the public booking window.
final adminSlotBlocksProvider = StreamProvider.autoDispose
    .family<Map<String, String>, String>((ref, day) {
      return ref
          .watch(firebaseBookingProvider)
          .db
          .collection('visitSlots')
          .where('visitDate', isEqualTo: day)
          .snapshots()
          .map(
            (snapshot) => {
              for (final doc in snapshot.docs)
                if (doc.data()['blocked'] == true)
                  doc.id: doc.data()['blockReason'] as String? ?? '',
            },
          );
    });

/// Share booking's server-calculated capacity, including active holds.
/// Saved slot, closure and configuration changes trigger an immediate refresh;
/// the shared availability provider also polls and refreshes on app resume.
final adminSlotStatusProvider = Provider.autoDispose
    .family<AsyncValue<Availability>, String>((ref, day) {
      void refreshOnChange<T>(AsyncValue<T>? previous, AsyncValue<T> next) {
        if (previous?.asData != null && next.asData != null) {
          ref.invalidate(availabilityProvider(day));
        }
      }

      ref.listen(adminSlotBlocksProvider(day), refreshOnChange);
      ref.listen(closedDaysProvider, refreshOnChange);
      ref.listen(configurationProvider, refreshOnChange);
      return ref.watch(availabilityProvider(day));
    });
