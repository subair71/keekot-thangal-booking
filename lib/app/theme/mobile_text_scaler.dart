import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A modest readability boost for small English text on mobile screens.
MediaQueryData mobileEnglishTypography(MediaQueryData media, String language) {
  if (language != 'en' ||
      media.size.width >= SanctuaryLayout.mobileBreakpoint) {
    return media;
  }
  return media.copyWith(textScaler: _SmallTextScaler(media.textScaler));
}

class _SmallTextScaler extends TextScaler {
  const _SmallTextScaler(this.systemScaler);

  final TextScaler systemScaler;

  @override
  double scale(double fontSize) {
    // Preserve larger body text and headings, and keep the size curve monotonic.
    final readableSize = fontSize < 16
        ? math.min(fontSize * 1.1, 16.0)
        : fontSize;
    return systemScaler.scale(readableSize);
  }

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _SmallTextScaler && other.systemScaler == systemScaler;

  @override
  int get hashCode => systemScaler.hashCode;
}
