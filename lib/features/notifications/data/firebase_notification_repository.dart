import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../../booking/data/firebase_booking_repository.dart';
import '../domain/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository(this.source, this.auth, this.config) {
    _authChanges = auth.idTokenChanges().listen((user) {
      if (user == null) {
        unawaited(_refresh?.cancel());
        _refresh = null;
      } else {
        unawaited(_restorePermission().catchError((Object _) {}));
      }
    });
  }
  final FirebaseBookingRepository source;
  final FirebaseAuth auth;
  final AppConfig config;
  StreamSubscription<String>? _refresh;
  StreamSubscription<User?>? _authChanges;
  bool _disposed = false, _registering = false;

  Future<void> _restorePermission() async {
    if (_disposed ||
        config.emulators ||
        config.vapidKey.isEmpty ||
        !await FirebaseMessaging.instance.isSupported()) {
      return;
    }
    final permission = await FirebaseMessaging.instance
        .getNotificationSettings();
    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      await _registerToken();
    }
  }

  Future<void> _registerToken() async {
    if (_disposed || _registering) return;
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    _registering = true;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken(vapidKey: config.vapidKey);
      if (_disposed || auth.currentUser?.uid != uid) return;
      if (token != null) await source.call('registerDevice', {'token': token});
      await _refresh?.cancel();
      if (_disposed || auth.currentUser?.uid != uid) return;
      _refresh = messaging.onTokenRefresh.listen((token) {
        if (!_disposed && auth.currentUser?.uid == uid) {
          unawaited(
            source
                .call('registerDevice', {'token': token})
                .catchError((Object _) => <String, dynamic>{}),
          );
        }
      });
    } finally {
      _registering = false;
    }
  }

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
    if (auth.currentUser == null) {
      throw const AppFailure('Sign in to enable reminders.');
    }
    if (config.emulators) {
      throw const AppFailure(
        'Push notifications can be tested on the staging website. Booking updates still appear here.',
      );
    }
    if (config.vapidKey.isEmpty ||
        !await FirebaseMessaging.instance.isSupported()) {
      throw const AppFailure(
        'Browser reminders are unavailable on this device. You can check updates here.',
      );
    }
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    await _registerToken();
    return true;
  });
  @override
  Future<void> disable() async {
    await _refresh?.cancel();
    if (config.emulators || !await FirebaseMessaging.instance.isSupported()) {
      return;
    }
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: config.vapidKey,
    );
    try {
      if (token != null && auth.currentUser != null) {
        await source.call('unregisterDevice', {'token': token});
      }
    } finally {
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  @override
  Future<void> markRead(String id) =>
      source.db.doc('notifications/$id').update({'read': true});
  @override
  void dispose() {
    _disposed = true;
    _refresh?.cancel();
    _authChanges?.cancel();
  }
}
