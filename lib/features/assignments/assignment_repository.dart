import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';

typedef Record = Map<String, dynamic>;

abstract class AssignmentRepository {
  Stream<List<Record>> bookings(String? uid);
  Stream<List<Record>> schedules(String? uid);
  Stream<List<Record>> staff();
  Future<Record> call(String name, Record data);
}

class FirebaseAssignments implements AssignmentRepository {
  FirebaseAssignments(this.invoke);
  final Future<Record> Function(String, Record) invoke;
  Stream<List<Record>> rows(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  @override
  Stream<List<Record>> bookings(String? uid) => rows(
    uid == null
        ? FirebaseFirestore.instance.collection('bookings')
        : FirebaseFirestore.instance
              .collection('bookings')
              .where('assignment.khadimId', isEqualTo: uid),
  );
  @override
  Stream<List<Record>> schedules(String? uid) => rows(
    uid == null
        ? FirebaseFirestore.instance.collection('khadimSchedules')
        : FirebaseFirestore.instance
              .collection('khadimSchedules')
              .where('khadimId', isEqualTo: uid),
  );
  @override
  Stream<List<Record>> staff() =>
      rows(FirebaseFirestore.instance.collection('khadims'));
  @override
  Future<Record> call(String name, Record data) => invoke(name, data);
}

final assignmentsRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => FirebaseAssignments(
    (name, data) => ref.read(firebaseBookingProvider).call(name, data),
  ),
);
final assignmentBookingsProvider = StreamProvider.autoDispose
    .family<List<Record>, String?>(
      (ref, uid) => ref.watch(assignmentsRepositoryProvider).bookings(uid),
    );
final assignmentSchedulesProvider = StreamProvider.autoDispose
    .family<List<Record>, String?>(
      (ref, uid) => ref.watch(assignmentsRepositoryProvider).schedules(uid),
    );
final assignmentStaffProvider = StreamProvider.autoDispose<List<Record>>(
  (ref) => ref.watch(assignmentsRepositoryProvider).staff(),
);
String serviceLabel(Record booking) =>
    switch ((booking['assignment'] as Map?)?['status']) {
      'assigned' => 'Assigned',
      'inProgress' => 'In progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Unassigned',
    };
