import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/bootstrap/providers.dart';
import '../../app/theme/app_theme.dart';
import '../localization/app_language.dart';
import '../utils/visit_clock.dart';
import 'sanctuary_navigation_drawer.dart';

class SanctuaryMobileHeader extends ConsumerWidget {
  const SanctuaryMobileHeader({super.key, this.keyboardOpen = false});
  final bool keyboardOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ml = AppLanguage.of(context) == 'ml';
    if (keyboardOpen) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const SanctuaryMenuButton(),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      AppBrand.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          ml ? AppBrand.name : 'KEEKKOTT SAYYID\nATTAKOYA THANGAL',
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 12,
            height: 1.35,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!ml && MediaQuery.textScalerOf(context).scale(1) <= 1.3)
          const _MaqamSubtitle(),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
          tooltip: tr(context, 'My Pass'),
          onPressed: () => context.go('/my-bookings'),
          icon: const Icon(Icons.confirmation_number_outlined, size: 19),
        ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
          tooltip: tr(context, 'Profile'),
          onPressed: () {
            final user = ref.read(authProvider).asData?.value;
            if (user == null) {
              context.go('/auth');
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
          icon: const Icon(Icons.account_circle, size: 23),
        ),
      ],
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: AppColors.canvas.withValues(alpha: .96),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const SanctuaryMenuButton(),
                      Expanded(child: identity),
                      controls,
                    ],
                  ),
                ),
                const _GateStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Matches the compact web header subtitle; wraps with accessible text sizes.
class _MaqamSubtitle extends StatelessWidget {
  const _MaqamSubtitle();

  @override
  Widget build(BuildContext context) => const AppText(
    'Chavakkad Maqam',
    style: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 11,
      height: 1.2,
      color: AppColors.muted,
    ),
  );
}

class _GateStatus extends ConsumerWidget {
  const _GateStatus();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    final day = VisitClock.today();
    final availability = ref.watch(availabilityProvider(day));
    final c = config.asData?.value;
    final a = availability.asData?.value;
    String label = 'Checking visiting hours…';
    if (config.hasError || availability.hasError) {
      label = 'Visiting hours unavailable';
    } else if (c != null && a != null) {
      // Use server time to avoid an incorrect gate status from the device clock.
      final custom = c.dateHours[day] as Map?;
      final open = VisitClock.epoch(
        day,
        custom?['openingTime'] as String? ?? c.openingTime,
      );
      final close = VisitClock.epoch(
        day,
        custom?['closingTime'] as String? ?? c.closingTime,
      );
      final inHours = !a.closed && a.serverNow >= open && a.serverNow < close;
      label =
          '${tr(context, a.closed
              ? 'No visits today'
              : inHours
              ? 'Within visiting hours'
              : 'Outside visiting hours')} · ${c.hoursForDate(day)}';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 2,
        children: [
          AppText(
            label,
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const AppText(
            'Free entry',
            style: TextStyle(
              fontSize: 9,
              height: 1.6,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class SanctuaryMobileNavigation extends StatelessWidget {
  const SanctuaryMobileNavigation({super.key});
  static const routes = [
    '/',
    '/book',
    '/?section=remembrance',
    '/?section=guide',
    '/?section=heritage',
  ];
  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final index = uri.path.startsWith('/book')
        ? 1
        : switch (uri.queryParameters['section']) {
            'remembrance' => 2,
            'guide' => 3,
            'heritage' => 4,
            _ => uri.path == '/' ? 0 : -1,
          };
    // Natural-height cells allow Malayalam and accessibility text to wrap.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: .96),
            border: const Border(top: BorderSide(color: AppColors.outline)),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: .05),
                blurRadius: 12,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < routes.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        child: InkWell(
                          onTap: () => context.go(routes[i]),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 52,
                              minWidth: 44,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 1,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    [
                                      Icons.temple_buddhist_outlined,
                                      Icons.calendar_month_outlined,
                                      Icons.auto_stories_outlined,
                                      Icons.volunteer_activism_outlined,
                                      Icons.history_edu_outlined,
                                    ][i],
                                    size: 22,
                                    color: i == index
                                        ? AppColors.primary
                                        : AppColors.muted,
                                  ),
                                  const SizedBox(height: 4),
                                  AppText(
                                    [
                                      'Home',
                                      'Book Slot',
                                      'Remembrance',
                                      'Etiquette',
                                      'Heritage',
                                    ][i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      height: 1.4,
                                      fontWeight: i == index
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: i == index
                                          ? AppColors.primary
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
