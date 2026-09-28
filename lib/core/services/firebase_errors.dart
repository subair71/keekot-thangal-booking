import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../errors/app_failure.dart';

AppFailure friendlyFailure(Object e) {
  if (e is AppFailure) return e;
  if (e is FirebaseFunctionsException && e.details is Map) {
    final message = (e.details as Map)['publicMessage'];
    if (message is String && message.length < 300) {
      return AppFailure(message, code: e.code);
    }
  }

  final code = e is FirebaseException ? e.code : 'unknown';
  final message = switch (code) {
    'invalid-phone-number' =>
      'Enter a valid mobile number, including the country code.',
    'invalid-verification-code' =>
      'That code is incorrect. Check the SMS and try again.',
    'session-expired' ||
    'code-expired' => 'This code has expired. Request a new code.',
    'too-many-requests' =>
      'Too many verification attempts. Please wait a while and try again.',
    'quota-exceeded' =>
      'The SMS verification quota has been reached. Please try again later.',
    'network-request-failed' ||
    'unavailable' ||
    'deadline-exceeded' => 'Please check your connection and try again.',
    'unauthenticated' => 'Please sign in again to continue.',
    'permission-denied' => 'You do not have access to this information.',
    'resource-exhausted' => 'This slot is full. Please choose another time.',
    'failed-precondition' =>
      'This request is no longer available. Please refresh and try again.',
    'not-found' => 'We could not find this booking.',
    'operation-not-allowed' =>
      'Phone sign-in is not enabled for this Firebase project.',
    'unauthorized-domain' ||
    'app-not-authorized' =>
      'This website domain is not authorized for phone verification. Please add subair71.github.io to Firebase Authentication authorized domains.',
    'captcha-check-failed' =>
      'The reCAPTCHA verification failed. Check that subair71.github.io is allowed in the reCAPTCHA/App Check configuration, then refresh and try again.',
    'invalid-app-credential' =>
      'Firebase could not validate the verification request. Check the authorized domain, reCAPTCHA configuration, and Firebase web app settings.',
    'missing-client-type' ||
    'missing-app-credential' =>
      'The phone verification configuration is incomplete. Please check the Firebase web authentication setup.',
    'billing-not-enabled' =>
      'SMS verification is unavailable because billing is not enabled for the Firebase project.',
    'invalid-api-key' ||
    'api-key-not-valid' =>
      'The Firebase web configuration is invalid. Please check the project API key.',
    _ => 'We could not complete this request. Error: $code.',
  };

  return AppFailure(message, code: code);
}

Future<T> protect<T>(Future<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    throw friendlyFailure(e);
  }
}
