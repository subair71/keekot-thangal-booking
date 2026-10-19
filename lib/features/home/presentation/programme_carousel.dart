import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';

/// Compact programme thumbnails, sized like the long-video gallery.
class ProgrammeCarousel extends StatefulWidget {
  const ProgrammeCarousel({super.key});

  @override
  State<ProgrammeCarousel> createState() => _ProgrammeCarouselState();
}

class _ProgrammeCarouselState extends State<ProgrammeCarousel>
    with WidgetsBindingObserver {
  static const _assets = ['dhikr', 'mawlid', 'annual'];
  static const _english = [
    ('Dhikr gathering', 'Every Thursday after Maghrib.'),
    (
      'Mawlid gathering',
      'On the 24th of every Hijri month: Keekkott Attakoya Uppappa.\nOn the 10th of every Hijri month: Ahlul Aba.',
    ),
    (
      'Annual commemorations',
      'Ramadan 8: Keekkott Valiya Uppappa.\nSafar 24: Keekkott Attakoya Uppappa.\nMuharram 10: Ahlul Aba.',
    ),
  ];
  static const _malayalam = [
    ('ദിക്ർ ഹൽഖ', 'എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'),
    (
      'മൗലിദ് സദസ്സ്',
      'എല്ലാ അറബിമാസം 24ന് മഹാനായ കീക്കോട്ട് ആറ്റക്കോയ ഉപ്പാപ്പാടെയും\nഎല്ലാ അറബിമാസം 10ന് അഹ്‌ലുൽ അബാഇന്റെയും',
    ),
    (
      'ആണ്ട് നേർച്ച',
      'റമദാൻ 8 ന് കീക്കോട്ട് വലിയ ഉപ്പാപ്പാടെ ആണ്ട്\nസഫർ 24 ന് കീക്കോട്ട് ആറ്റക്കോയ ഉപ്പാപ്പാടെ ആണ്ട്\nമുഹറം 10 ന് അഹ്‌ലുൽ അബാഇന്റെ ആണ്ട്',
    ),
  ];
  final _controller = ScrollController();
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;
  bool _touching = false;
  bool _active = true;
  double _stride = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
  }

  void _advance() {
    if (!mounted ||
        !_controller.hasClients ||
        !_active ||
        _hovered ||
        _focused ||
        _touching ||
        _controller.position.isScrollingNotifier.value ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context) ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _move(1);
  }

  void _move(int direction) {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return;
    final offset = _controller.offset;
    final target = direction > 0 && offset >= max - 1
        ? 0.0
        : (offset + direction * _stride).clamp(0.0, max).toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    }
  }

  void _details(int index, bool ml) {
    final programme = (ml ? _malayalam : _english)[index];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(programme.$1),
        content: SingleChildScrollView(child: Text(programme.$2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ml ? 'അടയ്ക്കുക' : 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ml = AppLanguage.of(context) == 'ml';
    final programmes = ml ? _malayalam : _english;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            ml ? 'പരിപാടികളും സദസ്സുകളും' : 'Programmes & gatherings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.sizeOf(context).width >= 1024 ? 4 : 2;
            final gap = constraints.maxWidth < 600 ? 12.0 : 20.0;
            final width = math.max(
              1.0,
              (constraints.maxWidth - gap * columns) / (columns + 0.25),
            );
            _stride = width + gap;
            final scaler = MediaQuery.textScalerOf(context);
            final height =
                width * 9 / 16 +
                scaler.scale(12) * 3 +
                scaler.scale(11) * 3.6 +
                16;
            return MouseRegion(
              onEnter: (_) => _hovered = true,
              onExit: (_) => _hovered = false,
              child: Focus(
                onFocusChange: (value) => _focused = value,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _move(
                      event.logicalKey == LogicalKeyboardKey.arrowRight
                          ? 1
                          : -1,
                    );
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Listener(
                  onPointerDown: (_) => _touching = true,
                  onPointerUp: (_) => _touching = false,
                  onPointerCancel: (_) => _touching = false,
                  child: SizedBox(
                    height: height,
                    child: ListView.separated(
                      key: const ValueKey('programme-thumbnail-list'),
                      controller: _controller,
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      itemCount: programmes.length,
                      separatorBuilder: (_, _) => SizedBox(width: gap),
                      itemBuilder: (context, index) {
                        final programme = programmes[index];
                        return SizedBox(
                          width: width,
                          child: Semantics(
                            button: true,
                            label: '${programme.$1}. ${programme.$2}',
                            onTap: () => _details(index, ml),
                            excludeSemantics: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('programme-thumbnail-$index'),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _details(index, ml),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.asset(
                                          'assets/brand/programme-${_assets[index]}-overlay-${ml ? 'ml' : 'en'}.webp',
                                          fit: BoxFit.cover,
                                          excludeFromSemantics: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      programme.$1,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: ml
                                            ? 'Noto Sans Malayalam'
                                            : null,
                                        fontSize: 12,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      programme.$2,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: ml
                                            ? 'Noto Sans Malayalam'
                                            : null,
                                        fontSize: 11,
                                        height: 1.8,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
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
      ],
    );
  }
}
