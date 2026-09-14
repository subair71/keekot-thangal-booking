import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/firebase_errors.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  ConfirmationResult? _confirmation;
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
    // FlutterFire owns the web reCAPTCHA lifecycle. No OTP is saved to Firestore.
    _confirmation = await auth.signInWithPhoneNumber(phone);
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
