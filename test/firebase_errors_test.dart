import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/services/firebase_errors.dart';

void main() {
  test(
    'rate limits show a retry message instead of claiming the slot is full',
    () {
      final error = friendlyFailure(
        FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'limited',
        ),
      );
      expect(error.message, contains('Too many requests'));
      expect(error.message, isNot(contains('slot is full')));
    },
  );

  test('capacity and attestation errors preserve safe server guidance', () {
    for (final entry in {
      'resource-exhausted': 'This slot no longer has enough places.',
      'unauthenticated':
          'App verification is required. Refresh the page and try again.',
    }.entries) {
      final error = friendlyFailure(
        FirebaseFunctionsException(
          code: entry.key,
          message: 'generic',
          details: {'publicMessage': entry.value},
        ),
      );
      expect(error.message, entry.value);
    }
  });
}
