import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/components.dart';
import '../data/sanctuary_content.dart';
import 'quick_booking_card.dart';
import 'media/sanctuary_video_archive.dart';

const _small = TextStyle(fontSize: 12, height: 1.55);
const _body = TextStyle(fontSize: 14, height: 1.6);

/// Mobile composition follows the supplied Stitch screenshot. The existing
/// desktop home and all authentication/booking routes remain independently intact.
class MobileSanctuaryHome extends ConsumerStatefulWidget {
  const MobileSanctuaryHome({super.key, this.section});
  final String? section;
  @override
  ConsumerState<MobileSanctuaryHome> createState() =>
      _MobileSanctuaryHomeState();
}

class _MobileSanctuaryHomeState extends ConsumerState<MobileSanctuaryHome> {
  final anchors = {
    for (final name in [
      'heritage',
      'book',
      'videos',
      'guide',
      'questions',
      'remembrance',
    ])
      name: GlobalKey(),
  };
  @override
  void initState() {
    super.initState();
    reveal();
  }

  @override
  void didUpdateWidget(covariant MobileSanctuaryHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section) reveal();
  }

  void reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final target = anchors[widget.section]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        alignment: .02,
      );
    }
  });
  Widget section(String name, Widget child) =>
      KeyedSubtree(key: anchors[name], child: child);
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    return SingleChildScrollView(
      key: const PageStorageKey('sanctuary-mobile-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section('heritage', const _HeritageHero()),
          const SizedBox(height: 16),
          section(
            'book',
            AsyncPanel(
              value: config,
              onRetry: () => ref.invalidate(configurationProvider),
              builder: (c) => QuickBookingCard(config: c, mobileDesign: true),
            ),
          ),
          const SizedBox(height: 32),
          section('videos', const SanctuaryVideoArchive()),
          const SizedBox(height: 32),
          const _VisitSteps(),
          const SizedBox(height: 32),
          section('remembrance', const _Programmes()),
          const SizedBox(height: 32),
          section('guide', const _Etiquette()),
          const SizedBox(height: 32),
          section('questions', const _Questions()),
          const SizedBox(height: 32),
          const _Location(),
        ],
      ),
    );
  }
}

class SanctuaryHeading extends StatelessWidget {
  const SanctuaryHeading(
    this.eyebrow,
    this.title,
    this.subtitle, {
    super.key,
    this.dark = false,
    this.center = false,
    this.showSubtitleInEnglish = false,
  });
  final String eyebrow, title, subtitle;
  final bool dark, center, showSubtitleInEnglish;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      AppText(
        eyebrow,
        textAlign: center ? TextAlign.center : null,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: dark ? AppColors.mintStrong : AppColors.secondary,
        ),
      ),
      const SizedBox(height: 4),
      Semantics(
        header: true,
        child: AppText(
          title,
          textAlign: center ? TextAlign.center : null,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 26,
            height: 1.3,
            color: dark ? AppColors.ivory : AppColors.primary,
          ),
        ),
      ),
      if (subtitle.isNotEmpty &&
          (showSubtitleInEnglish || AppLanguage.of(context) == 'ml'))
        AppText(
          subtitle,
          textAlign: center ? TextAlign.center : null,
          style: TextStyle(
            fontFamily: AppLanguage.of(context) == 'ml'
                ? 'Noto Sans Malayalam'
                : 'Plus Jakarta Sans',
            fontSize: 12,
            height: 1.65,
            color: dark ? AppColors.mintStrong : AppColors.muted,
          ),
        ),
    ],
  );
}

class _HeritageHero extends ConsumerWidget {
  const _HeritageHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).asData?.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/brand/maqam-hero.png',
              fit: BoxFit.cover,
              alignment: const Alignment(.25, 0),
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.forest.withValues(alpha: .62),
                    AppColors.forest.withValues(alpha: .68),
                    AppColors.forest.withValues(alpha: .92),
                  ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ivory.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const AppText(
                    'Historic Sanctuary · Chavakkad',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.ivory,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const AppText(
                  'A peaceful place.\nA heartfelt visit.',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 10),
                if (AppLanguage.of(context) == 'ml')
                  const AppText(
                    'സമാധാനപൂർണ്ണമായ ഒരിടം. ഹൃദയസ്പർശിയായ സന്ദർശനം.',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Malayalam',
                      fontSize: 12,
                      height: 1.65,
                      color: AppColors.mintStrong,
                    ),
                  ),
                const SizedBox(height: 10),
                const AppText(
                  'Plan a reverent visit with Mr. Sayyid Ali Noufal Thangal Al-Aidrose Keekkott for spiritual counsel, guidance, and authentic dua at the sanctified family bungalow.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final scaled =
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final tiles = [
                      (
                        Icons.schedule,
                        config == null
                            ? 'Visit Slots'
                            : '${config.slotDurationMinutes}-Min Slots',
                        'Dedicated time',
                      ),
                      (
                        Icons.location_on_outlined,
                        'Chavakkad',
                        'Kerala, India',
                      ),
                      (Icons.qr_code_2, 'Digital Pass', 'Instant QR gate'),
                    ];
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in tiles)
                          Container(
                            width: scaled ? c.maxWidth : (c.maxWidth - 12) / 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ivory.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  t.$1,
                                  color: AppColors.mintStrong,
                                  size: 18,
                                ),
                                AppText(
                                  t.$2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ivory,
                                  ),
                                ),
                                AppText(
                                  t.$3,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.ivory,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitSteps extends ConsumerWidget {
  const _VisitSteps();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref
        .watch(configurationProvider)
        .asData
        ?.value
        .slotDurationMinutes;
    final steps = [
      (
        duration == null
            ? 'Select Date & Visit Slot'
            : 'Select Date & $duration-Minute Slot',
        'Choose your preferred date and convenient time window. Each pilgrim family receives dedicated consultation without crowd pressure.',
        'സൗകര്യപ്രദമായ തീയതിയും സമയവും തിരഞ്ഞെടുക്കുക',
      ),
      (
        'Quick Mobile Verification',
        'Enter your mobile number to receive an OTP. No personal document uploads or fee payments are ever required.',
        'മൊബൈൽ നമ്പർ നൽകി വേരിഫിക്കേഷൻ പൂർത്തിയാക്കുക',
      ),
      (
        'Receive Digital Entry Pass',
        'Your high-contrast QR entry pass is generated after confirmation for scanning at the Khadim desk. Save the PDF to your phone.',
        'ഡിജിറ്റൽ ക്യുആർ പാസ് ഗേറ്റിൽ കാണിക്കുക',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SanctuaryHeading(
          'SEAMLESS PILGRIM PATH',
          '3 Simple Steps to Visit',
          'സന്ദർശനം 3 ലളിതമായ ഘട്ടങ്ങളിൽ',
          center: true,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              color: AppColors.cream,
              padding: 14,
              borderColor: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.emerald,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.mintStrong,
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          steps[i].$1,
                          style: _body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        AppText(steps[i].$2, style: _small),
                        const SizedBox(height: 4),
                        if (AppLanguage.of(context) == 'ml')
                          AppText(
                            steps[i].$3,
                            style: _small.copyWith(
                              fontFamily: 'Noto Sans Malayalam',
                              fontSize: 10,
                              color: AppColors.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Programmes extends ConsumerWidget {
  const _Programmes();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SurfaceCard(
    color: AppColors.forest,
    padding: 16,
    borderColor: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SanctuaryHeading(
          'SPIRITUAL CALENDAR',
          'Programmes & Gatherings',
          'ആത്മീയ സംഗമങ്ങളുടെ വിവരങ്ങൾ',
          dark: true,
        ),
        const SizedBox(height: 14),
        for (final p in ref.watch(sanctuaryContentProvider).programmes)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ivory.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppText(
                      p.$1,
                      style: _small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mintStrong,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintStrong,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: AppText(
                        p.$3,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (AppLanguage.of(context) == 'ml')
                  AppText(
                    p.$2,
                    style: _small.copyWith(
                      fontFamily: 'Noto Sans Malayalam',
                      fontSize: 10,
                      color: AppColors.mintStrong,
                    ),
                  ),
                const SizedBox(height: 6),
                AppText(
                  p.$4,
                  style: _small.copyWith(
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppText(p.$5, style: _small.copyWith(color: AppColors.ivory)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Etiquette extends StatelessWidget {
  const _Etiquette();
  @override
  Widget build(BuildContext context) {
    const rules = [
      (
        Icons.checkroom_outlined,
        'Modest Attire',
        'Please dress modestly in accordance with spiritual sanctuary custom.',
        'മാന്യമായ വസ്ത്രധാരണം',
      ),
      (
        Icons.phonelink_ring_outlined,
        'Silent Phones',
        'Keep phones on silent or switched off inside the inner chambers.',
        'ഫോൺ സൈലന്റാക്കുക',
      ),
      (
        Icons.badge_outlined,
        'Pass Ready',
        'Keep digital QR pass accessible on your screen at the main gate.',
        'ക്യുആർ പാസ് കാണിക്കുക',
      ),
      (
        Icons.volunteer_activism_outlined,
        'No Fees / Charges',
        'All counsel and entry is entirely free. Please report any unauthorized soliciting.',
        'പൂർണ്ണമായും സൗജന്യം',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SanctuaryHeading(
          'REVERENCE & PEACE',
          'Visiting Etiquette',
          'സന്ദർശകർ ശ്രദ്ധിക്കേണ്ട മര്യാദകൾ',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cols = MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final r in rules)
                  SizedBox(
                    width: (c.maxWidth - (cols - 1) * 10) / cols,
                    child: SurfaceCard(
                      color: AppColors.cream,
                      padding: 12,
                      borderColor: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.disabled,
                            child: Icon(
                              r.$1,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppText(
                            r.$2,
                            style: _small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          AppText(r.$3, style: _small.copyWith(fontSize: 11)),
                          const SizedBox(height: 5),
                          if (AppLanguage.of(context) == 'ml')
                            AppText(
                              r.$4,
                              style: _small.copyWith(
                                fontFamily: 'Noto Sans Malayalam',
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Questions extends ConsumerStatefulWidget {
  const _Questions();
  @override
  ConsumerState<_Questions> createState() => _QuestionsState();
}

class _QuestionsState extends ConsumerState<_Questions> {
  int? expanded;
  @override
  Widget build(BuildContext context) {
    final minutes = ref
        .watch(configurationProvider)
        .asData
        ?.value
        .slotDurationMinutes;
    final questions = [
      (
        minutes == null
            ? 'Why are visits scheduled in time slots?'
            : 'Why are visits scheduled in $minutes-minute slots?',
        'The allocated window ensures each family receives unhurried, private time for personal dua and spiritual advice without overcrowded waiting halls. It honors every visitor’s time and devotion.',
      ),
      (
        'Are there any fees or donations required for booking?',
        'Absolutely not. Visiting Keekkott Maqam and receiving spiritual advice is completely free. The digital pass exists solely for crowd management and orderly pilgrim reception.',
      ),
      (
        'Can I bring elderly family members or wheelchairs?',
        'Yes. Ground-floor access is prioritized. The Khadim volunteers are stationed at the main entrance to assist wheelchair access directly into the counseling veranda.',
      ),
      (
        'What if I need to cancel or change my reserved time?',
        'Open your digital pass using your verified phone number. Cancel an eligible booking from My Bookings, then choose a new slot. Releasing an unwanted slot allows waiting families to visit.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SanctuaryHeading(
          'CLEAR GUIDANCE',
          'Frequently Asked Questions',
          'പതിവായി ചോദിക്കുന്ന ചോദ്യങ്ങൾ',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Semantics(
                    expanded: expanded == i,
                    child: InkWell(
                      onTap: () =>
                          setState(() => expanded = expanded == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                questions[i].$1,
                                style: _small.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: expanded == i ? .5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(
                                Icons.expand_more,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: expanded == i
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: AppText(questions[i].$2, style: _body),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Location extends ConsumerWidget {
  const _Location();
  Future<void> open(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        showMessage(context, 'Unable to open this link. Please try again.');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Unable to open this link. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).asData?.value;
    final content = ref.watch(sanctuaryContentProvider);
    final configured = Uri.tryParse(config?.locationUrl ?? '');
    final location =
        configured != null && ['https', 'http'].contains(configured.scheme)
        ? configured
        : Uri.parse('https://maps.app.goo.gl/EeBuXUcd7LHgeig17?g_st=ic');
    return SurfaceCard(
      color: AppColors.cream,
      padding: 16,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SanctuaryHeading('SANCTUARY LOCATION', 'Keekkott Bungalow', ''),
          const AppText(
            'Chavakkad, Thrissur District, Kerala 680506, India.',
            style: _small,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/brand/stitch/map.jpg',
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () => open(context, location),
                      icon: const Icon(Icons.near_me_outlined, size: 16),
                      label: const AppText(
                        'Open in Google Maps',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () =>
                open(context, Uri(scheme: 'mailto', path: content.email)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(content.email, style: _small)),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.support_agent,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(child: AppText(content.assistanceHours, style: _small)),
            ],
          ),
          TextButton(
            onPressed: () => context.go('/contact'),
            child: const AppText('Contact us'),
          ),
        ],
      ),
    );
  }
}
