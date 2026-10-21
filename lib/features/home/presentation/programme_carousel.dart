import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';

/// Full artwork with compact desktop cards and two-thirds-width mobile cards.
class ProgrammeCarousel extends StatefulWidget {
  const ProgrammeCarousel({super.key});

  @override
  State<ProgrammeCarousel> createState() => _ProgrammeCarouselState();
}

class _ProgrammeCarouselState extends State<ProgrammeCarousel> {
  final _controller = ScrollController();
  Timer? _timer;
  bool _hovering = false;
  bool _touching = false;
  bool _reduceMotion = false;
  double _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_hovering || _touching || _reduceMotion) return;
      if (!_controller.hasClients) return;
      final position = _controller.position;
      if (position.isScrollingNotifier.value || position.maxScrollExtent <= 0) {
        return;
      }
      final target = position.pixels >= position.maxScrollExtent - 1
          ? 0.0
          : math.min(position.pixels + _step, position.maxScrollExtent);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ml = AppLanguage.of(context) == 'ml';
    final banners = [
      (
        asset: 'assets/brand/programme-dhikr-compact.webp',
        title: ml ? 'ദിക്ർ ഹൽഖ' : 'Weekly Dhikr',
        label: ml
            ? 'ദിക്ർ ഹൽഖ. എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'
            : 'Dhikr gathering. Every Thursday after Maghrib.',
      ),
      (
        asset: 'assets/brand/programme-mawlid-corrected.webp',
        title: ml ? 'മൗലിദ് സദസ്സ്' : 'Mawlid gathering',
        label: ml ? 'മൗലിദ് പരിപാടി' : 'Mawlid programme.',
      ),
      (
        asset: 'assets/brand/programme-annual-compact.webp',
        title: ml ? 'ആണ്ട് നേർച്ച' : 'Annual remembrance',
        label: ml ? 'വാർഷിക പരിപാടി' : 'Annual programme.',
      ),
    ];

    final strip = LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 600 ? 12.0 : 16.0;
        final width = math.min(
          math.min(MediaQuery.sizeOf(context).width * 2 / 3, 360.0),
          constraints.maxWidth,
        );
        _step = width + gap;

        return MouseRegion(
          onEnter: (_) => _hovering = true,
          onExit: (_) => _hovering = false,
          child: Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) => _touching = false,
            onPointerCancel: (_) => _touching = false,
            child: SizedBox(
              height: width * 9 / 16 + 48,
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
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: banners.length * 2,
                  separatorBuilder: (context, index) => SizedBox(width: gap),
                  itemBuilder: (context, index) {
                    final banner = banners[index % banners.length];
                    return SizedBox(
                      width: width,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: AppColors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.asset(
                                  banner.asset,
                                  fit: BoxFit.contain,
                                  semanticLabel: banner.label,
                                ),
                              ),
                              SizedBox(
                                height: 48,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 16,
                                        color: AppColors.gold,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AppText(
                                          banner.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.emerald,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: AppText(
                    ml ? 'ആത്മീയ സംഗമങ്ങൾ' : 'Spiritual gatherings',
                    style: TextStyle(
                      fontFamily: 'Newsreader',
                      color: AppColors.ink,
                      fontSize: MediaQuery.sizeOf(context).width < 600 ? 22 : 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 32, height: 2, color: AppColors.gold),
            ],
          ),
        ),
        strip,
      ],
    );
  }
}
