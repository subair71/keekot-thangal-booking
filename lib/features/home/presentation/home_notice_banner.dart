import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/utils/visit_clock.dart';
import '../../notifications/domain/home_notice.dart';
import 'notice_reason_ticker.dart';

final homeNoticeClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class HomeNoticeBanner extends ConsumerStatefulWidget {
  const HomeNoticeBanner({super.key});

  @override
  ConsumerState<HomeNoticeBanner> createState() => _HomeNoticeBannerState();
}

class _HomeNoticeBannerState extends ConsumerState<HomeNoticeBanner> {
  Timer? expiry;
  late final AppLifecycleListener lifecycle;

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    expiry?.cancel();
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(configurationProvider).asData?.value.homeNotice;
    final now = ref.read(homeNoticeClockProvider)();
    expiry?.cancel();
    if (notice == null || !notice.visibleAt(now)) {
      return const SizedBox.shrink();
    }
    expiry = Timer(
      Duration(milliseconds: notice.expiresAt - now.millisecondsSinceEpoch),
      () {
        if (mounted) setState(() {});
      },
    );
    return Padding(
      key: const ValueKey('home-notice-banner'),
      padding: const EdgeInsets.only(bottom: 12),
      child: HomeNoticeCard(key: ValueKey(notice.identity), notice: notice),
    );
  }
}

class HomeNoticeCard extends StatelessWidget {
  const HomeNoticeCard({super.key, required this.notice, this.animate = true});
  final HomeNotice notice;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate && !reduceMotion ? 0 : 1, end: 1),
      duration: animate && !reduceMotion
          ? const Duration(milliseconds: 380)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -12 * (1 - value)),
          child: child,
        ),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4DE),
            border: Border.all(color: const Color(0xFFE7C681)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF8C571B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const AppText(
                          'Important visit notice',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppText(
                          VisitClock.dayLabel(notice.visitDate),
                          style: const TextStyle(
                            color: Color(0xFF8C571B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              NoticeReasonTicker(
                text: notice.reason,
                animate: animate,
                style: const TextStyle(
                  color: AppColors.ink,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
