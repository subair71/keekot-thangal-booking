import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';

/// Compact 16:9 thumbnails with two full banners and a preview of the next.
class ProgrammeCarousel extends StatelessWidget {
  const ProgrammeCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final ml = AppLanguage.of(context) == 'ml';
    final banners = [
      (
        asset: 'assets/brand/programme-dhikr.webp',
        label: ml
            ? 'ദിക്ർ ഹൽഖ. എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'
            : 'Dhikr gathering. Every Thursday after Maghrib.',
      ),
      (
        asset: 'assets/brand/programme-mawlid.webp',
        label: ml ? 'മൗലിദ് പരിപാടി' : 'Mawlid programme.',
      ),
      (
        asset: 'assets/brand/programme-annual.webp',
        label: ml ? 'വാർഷിക പരിപാടി' : 'Annual programme.',
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 600 ? 8.0 : 12.0;
            final width = (constraints.maxWidth - 2 * gap) / 2.3;

            return SizedBox(
              height: width * 9 / 16,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: ListView.separated(
                  key: const ValueKey('programme-thumbnail-strip'),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: banners.length,
                  separatorBuilder: (context, index) => SizedBox(width: gap),
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return SizedBox(
                      width: width,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            banner.asset,
                            fit: BoxFit.cover,
                            semanticLabel: banner.label,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
