import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';

/// The first original programme banner, displayed in the current 16:9 style.
class ProgrammeCarousel extends StatelessWidget {
  const ProgrammeCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final ml = AppLanguage.of(context) == 'ml';
    final description = ml
        ? 'ദിക്ർ ഹൽഖ. എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'
        : 'Dhikr gathering. Every Thursday after Maghrib.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              'assets/brand/programme-dhikr.webp',
              fit: BoxFit.cover,
              semanticLabel: description,
            ),
          ),
        ),
      ),
    );
  }
}
