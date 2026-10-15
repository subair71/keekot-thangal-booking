import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';

/// Regenerated programme images with smaller lettering and accessible descriptions.
class ProgrammeCarousel extends StatefulWidget {
  const ProgrammeCarousel({super.key});

  @override
  State<ProgrammeCarousel> createState() => _ProgrammeCarouselState();
}

class _ProgrammeCarouselState extends State<ProgrammeCarousel>
    with WidgetsBindingObserver {
  static const _slides = [
    ('ദിക്ർ ഹൽഖ', ['എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം']),
    (
      'assets/brand/programme-mawlid-small.webp',
      'മൗലിദ് സദസ്സ്',
      [
        'എല്ലാ അറബിമാസം 24ന്\nമഹാനായ കീക്കോട്ട് ആറ്റക്കോയ ഉപ്പാപ്പാടെയും',
        'എല്ലാ അറബിമാസം 10ന്\nഅഹ്‌ലുൽ അബാഇന്റെയും',
      ],
    ),
    (
      'assets/brand/programme-annual-small.webp',
      'ആണ്ട് നേർച്ച',
      [
        'റമദാൻ 8 ന് കീക്കോട്ട് വലിയ ഉപ്പാപ്പാടെ ആണ്ട്',
        'സഫർ 24 ന് കീക്കോട്ട് ആറ്റക്കോയ ഉപ്പാപ്പാടെ ആണ്ട്',
        'മുഹറം 10 ന് അഹ്‌ലുൽ അബാഇന്റെ ആണ്ട്',
      ],
    ),
  ];

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _hovered = false;
  bool _focused = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted ||
        _hovered ||
        _focused ||
        !_active ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    _timer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_controller.hasClients &&
          !_controller.position.isScrollingNotifier.value &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _show(_index + 1);
      } else {
        _schedule();
      }
    });
  }

  void _show(int index) {
    if (!_controller.hasClients) return;
    final target = index % _slides.length;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
    _schedule();
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
    String label(String english, String malayalam) => ml ? malayalam : english;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Focus(
          onFocusChange: (focused) {
            _focused = focused;
            _schedule();
          },
          child: MouseRegion(
            onEnter: (_) {
              _hovered = true;
              _schedule();
            },
            onExit: (_) {
              _hovered = false;
              _schedule();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label('Programmes & gatherings', 'പരിപാടികളും സദസ്സുകളും'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: ml ? 'Noto Sans Malayalam' : null,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _index = index);
                        _schedule();
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Image.asset(
                          slide.$1,
                          fit: BoxFit.contain,
                          semanticLabel: '${slide.$2}. ${slide.$3.join('. ')}',
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
