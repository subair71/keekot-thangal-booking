import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  ConfirmationResult? _confirmation;
  bool _sending = false;
  @override
  Stream<AppUser?> get userChanges {
    late StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    staffSubscription;
    var generation = 0;
    controller = StreamController<AppUser?>(
      onListen: () {
        authSubscription = auth.idTokenChanges().listen((user) async {
          final current = ++generation;
          await staffSubscription?.cancel();
          staffSubscription = null;
          if (current != generation || controller.isClosed) return;
          if (user == null) {
            controller.add(null);
            return;
          }
          try {
            final token = await user.getIdTokenResult();
            if (current != generation || controller.isClosed) return;
            if (token.claims?['khadimVersion'] != null) {
              staffSubscription = FirebaseFirestore.instance
                  .doc('khadims/${user.uid}')
                  .snapshots()
                  .listen((snapshot) {
                    if (current != generation || controller.isClosed) return;
                    final data = snapshot.data();
                    final valid =
                        data?['enabled'] == true &&
                        data?['version'] == token.claims?['khadimVersion'];
                    if (!valid) {
                      unawaited(auth.signOut());
                      return;
                    }
                    controller.add(
                      AppUser(
                        user.uid,
                        data?['phone'] as String? ?? '',
                        permissions: List<String>.from(
                          data?['permissions'] ?? [],
                        ),
                      ),
                    );
                  }, onError: controller.addError);
            } else {
              controller.add(
                AppUser(
                  user.uid,
                  user.phoneNumber ?? '',
                  admin: token.claims?['admin'] == true,
                  gate: token.claims?['gate'] == true,
                ),
              );
            }
          } catch (error, stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          }
        }, onError: controller.addError);
      },
      onCancel: () async {
        generation++;
        await authSubscription?.cancel();
        await staffSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> sendCode(String phone) => protect(() async {
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone)) {
      throw const AppFailure(
        'Enter a valid number including the country code.',
      );
    }
    if (_sending) {
      throw const AppFailure('A verification request is already in progress.');
    }
    _sending = true;
    _confirmation = null;
    try {
      // Use FirebaseAuth's existing delegate. Creating another platform
      // delegate replaces the web auth streams and breaks router listeners.
      _confirmation = await auth
          .signInWithPhoneNumber(phone)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw const AppFailure(
              'Verification took too long. Refresh the page and request a new code.',
            ),
          );
    } finally {
      _sending = false;
    }
  });
  @override
  Future<void> verifyCode(String code) => protect(() async {
    if (_confirmation == null) {
      throw const AppFailure('Request a new verification code.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AppFailure('Enter the 6-digit SMS code.');
    }
    await _confirmation!
        .confirm(code)
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw const AppFailure(
            'Sign-in is taking too long. Check your connection and try again.',
          ),
        );
  });
  @override
  Future<void> signOut() => protect(auth.signOut);
}
