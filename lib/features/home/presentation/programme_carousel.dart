import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

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
                      controller: _controller,
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
                                fit: BoxFit.contain,
                                semanticLabel: banner.label,
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
        ),
      ),
    );
  }
}
