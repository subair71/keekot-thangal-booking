import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show FirebaseAuthPlatform;

import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  ConfirmationResult? _confirmation;
  bool _sending = false;
  @override
  Stream<AppUser?> get userChanges =>
      auth.idTokenChanges().asyncMap((user) async {
        if (user == null) return null;
        final token = await user.getIdTokenResult();
        return AppUser(
          user.uid,
          user.phoneNumber ?? '',
          admin: token.claims?['admin'] == true,
          gate: token.claims?['gate'] == true,
        );
      });
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
    RecaptchaVerifier? verifier;
    final failure = Completer<ConfirmationResult>();
    try {
      verifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instanceFor(
          app: auth.app,
          pluginConstants: const {},
        ),
        onError: (error) {
          if (!failure.isCompleted) failure.completeError(error);
        },
        onExpired: () {
          if (!failure.isCompleted) {
            failure.completeError(
              const AppFailure(
                'Verification expired. Please request a new code.',
              ),
            );
          }
        },
      );
      // Own the verifier so failed and timed-out challenges are also removed.
      // Await before assigning: a late response cannot replace a newer request.
      _confirmation =
          await Future.any([
            auth.signInWithPhoneNumber(phone, verifier),
            failure.future,
          ]).timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw const AppFailure(
              'Verification took too long. Complete the security check if shown, '
              'check your connection, and try again.',
            ),
          );
    } finally {
      _sending = false;
      verifier?.clear();
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
    await _confirmation!.confirm(code);
  });
  @override
  Future<void> signOut() => protect(auth.signOut);
}
