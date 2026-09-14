import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../../booking/data/firebase_booking_repository.dart';
import '../domain/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository(this.source, this.auth, this.config);
  final FirebaseBookingRepository source;
  final FirebaseAuth auth;
  final AppConfig config;
  StreamSubscription<String>? _refresh;
  @override
  Stream<List<VisitNotice>> notices(String uid) => source.db
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => s.docs
            .map(
              (d) => VisitNotice(
                d.id,
                d.data()['title'] as String,
                d.data()['body'] as String,
                d.data()['bookingId'] as String,
                d.data()['read'] == true,
              ),
            )
            .toList(),
      );
  @override
  Stream<String> get foregroundMessages => FirebaseMessaging.onMessage.map(
    (m) => m.notification?.body ?? 'You have a booking update.',
  );
  @override
  Future<bool> enable() => protect(() async {
    if (auth.currentUser == null)
      throw const AppFailure('Sign in to enable reminders.');
    if (config.emulators)
      throw const AppFailure(
        'Push notifications can be tested on the staging website. Booking updates still appear here.',
      );
    if (config.vapidKey.isEmpty || !await FirebaseMessaging.isSupported())
      throw const AppFailure(
        'Browser reminders are unavailable on this device. You can check updates here.',
      );
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized)
      return false;
    final token = await messaging.getToken(vapidKey: config.vapidKey);
    if (token != null) await source.call('registerDevice', {'token': token});
    await _refresh?.cancel();
    _refresh = messaging.onTokenRefresh.listen((token) {
      if (auth.currentUser != null)
        unawaited(
          source
              .call('registerDevice', {'token': token})
              .catchError((Object _) => <String, dynamic>{}),
        );
    });
    return true;
  });
  @override
  Future<void> disable() async {
    await _refresh?.cancel();
    if (config.emulators || !await FirebaseMessaging.isSupported()) return;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: config.vapidKey,
    );
    if (token != null && auth.currentUser != null)
      await source.call('unregisterDevice', {'token': token});
    await FirebaseMessaging.instance.deleteToken();
  }

  @override
  Future<void> markRead(String id) =>
      source.db.doc('notifications/$id').update({'read': true});
  @override
  void dispose() {
    _refresh?.cancel();
  }
}
