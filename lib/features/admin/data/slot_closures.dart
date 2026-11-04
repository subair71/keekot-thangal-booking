import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';

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
