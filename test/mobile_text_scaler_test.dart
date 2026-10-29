import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/theme/mobile_text_scaler.dart';

void main() {
  const mobile = MediaQueryData(size: Size(390, 844));

  test('English mobile small text grows without changing headings', () {
    final scaler = mobileEnglishTypography(mobile, 'en').textScaler;
    expect(scaler.scale(10), closeTo(11, .001));
    expect(scaler.scale(14), closeTo(15.4, .001));
    expect(scaler.scale(16), 16);
    expect(scaler.scale(28), 28);
    for (var size = 0.0; size < 30; size += .1) {
      expect(scaler.scale(size + .1), greaterThanOrEqualTo(scaler.scale(size)));
    }
  });

  test('Malayalam and desktop retain their existing typography', () {
    expect(mobileEnglishTypography(mobile, 'ml'), same(mobile));
    final desktop = mobile.copyWith(size: const Size(768, 1024));
    expect(mobileEnglishTypography(desktop, 'en'), same(desktop));
  });

  test(
    'device accessibility scaling is preserved after the small text boost',
    () {
      final media = mobile.copyWith(textScaler: const TextScaler.linear(2));
      final scaler = mobileEnglishTypography(media, 'en').textScaler;
      expect(scaler.scale(14), closeTo(30.8, .001));
      expect(scaler.scale(28), 56);
    },
  );
}
