import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../errors/app_failure.dart';

AppFailure friendlyFailure(Object e) {
  if (e is AppFailure) return e;
  if (e is FirebaseFunctionsException && e.details is Map) {
    final message = (e.details as Map)['publicMessage'];
    if (message is String && message.length < 300)
      return AppFailure(message, code: e.code);
  }
  final code = e is FirebaseException ? e.code : 'unknown';
  return AppFailure(switch (code) {
    'invalid-phone-number' =>
      'Enter a valid mobile number, including the country code.',
    'invalid-verification-code' =>
      'That code is incorrect. Check the SMS and try again.',
    'session-expired' ||
    'code-expired' => 'This code has expired. Request a new code.',
    'too-many-requests' ||
    'quota-exceeded' => 'Too many attempts. Please wait before trying again.',
    'network-request-failed' ||
    'unavailable' ||
    'deadline-exceeded' => 'Please check your connection and try again.',
    'unauthenticated' => 'Please sign in again to continue.',
    'permission-denied' => 'You do not have access to this information.',
    'resource-exhausted' => 'This slot is full. Please choose another time.',
    'failed-precondition' =>
      'This request is no longer available. Please refresh and try again.',
    'not-found' => 'We could not find this booking.',
    'captcha-check-failed' || 'invalid-app-credential' =>
      'Verification could not finish. Please refresh and try again.',
    _ => 'We could not complete this request. Please try again.',
  }, code: code);
}

Future<T> protect<T>(Future<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    throw friendlyFailure(e);
  }
}
