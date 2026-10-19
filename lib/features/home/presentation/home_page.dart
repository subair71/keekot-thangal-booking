import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';
import '../../visitor_information/presentation/information_page.dart';
import 'media/video_gallery.dart';
import 'home_footer.dart';
import 'programme_carousel.dart';
import 'media/youtube_player.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.section});
  final String? section;
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final videosKey = GlobalKey(),
      guideKey = GlobalKey(),
      questionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSection();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revealSection();
  }

  void _revealSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = switch (widget.section) {
        'guide' => guideKey,
        'videos' => videosKey,
        'questions' => questionsKey,
        _ => null,
      };
      if (key != null) reveal(key);
    });
  }

  void reveal(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration:
          MediaQuery.disableAnimationsOf(context) ||
              MediaQuery.accessibleNavigationOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    return PageContainer(
      width: 1320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availability = AsyncPanel(
                value: config,
                onRetry: () => ref.invalidate(configurationProvider),
                builder: (c) => _LiveAvailability(c),
              );
              if (constraints.maxWidth < 1050) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MaqamHero(),
                    const SizedBox(height: 20),
                    availability,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: _MaqamHero()),
                  const SizedBox(width: 28),
                  SizedBox(width: 340, child: availability),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AsyncPanel(
            value: config,
            onRetry: () => ref.invalidate(configurationProvider),
            builder: (c) => SurfaceCard(
              child: _FeatureGrid(
                children: [
                  InfoLine(
                    Icons.schedule_outlined,
                    'Visiting hours',
                    c.hoursForDate(VisitClock.today()),
                  ),
                  InfoLine(
                    Icons.hourglass_bottom_outlined,
                    'Time for your visit',
                    '${c.slotDurationMinutes} minutes per slot',
                  ),
                  const InfoLine(
                    Icons.location_on_outlined,
                    'Find us',
                    'Chavakkad, Kerala',
                  ),
                  const InfoLine(
                    Icons.confirmation_number_outlined,
                    'Easy entry',
                    'Your booking. Your digital pass.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ProgrammeCarousel(),
          const SizedBox(height: 32),
          const _HomeFeaturedVideo(),
          const SizedBox(height: 56),
          TwoColumn(
            main: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'WELCOME TO KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
                  'A place for remembrance.\nA moment for yourself.',
                ),
                SizedBox(height: 20),
                AppText(
                  'Assalamu alaikum. Welcome to Keekkott Sayyid Attakoya Thangal Maqam in Chavakkad, Kerala. Make time for ziyarat, dua and quiet reflection, and approach your visit with a spirit of respect and consideration.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 18),
                AppText(
                  'This visitor service helps you plan ahead: explore available dates, reserve a suitable time and keep your entry pass close at hand. Whether you are visiting on your own or accompanying family, a little preparation helps everyone arrive with peace of mind.',
                ),
                SizedBox(height: 18),
                _FeatureGrid(
                  children: [
                    InfoLine(
                      Icons.auto_awesome_outlined,
                      'Remembrance & dua',
                      'Set aside the rush of the day for a thoughtful visit.',
                    ),
                    InfoLine(
                      Icons.people_outline,
                      'Care for one another',
                      'Give fellow visitors the space and quiet they need.',
                    ),
                  ],
                ),
              ],
            ),
            aside: const LocationCard(),
          ),
          const SizedBox(height: 56),
          Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 24 : 36,
            ),
            decoration: BoxDecoration(
              color: AppColors.mint,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'YOUR VISIT, SIMPLIFIED',
                  'Arrive prepared. Be fully present.',
                ),
                SizedBox(height: 20),
                _FeatureGrid(
                  children: [
                    _VisitStep(
                      '01',
                      'Choose your time',
                      'Select an available date and time that works for you. Check the latest schedule before making travel plans.',
                    ),
                    _VisitStep(
                      '02',
                      'Confirm your details',
                      'Verify your mobile number and add the visitor details requested to complete your reservation.',
                    ),
                    _VisitStep(
                      '03',
                      'Keep your pass ready',
                      'Open My Bookings to access your QR pass and token details. Follow the arrival time on your booking.',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 56),
          KeyedSubtree(key: videosKey, child: const VideoGallery()),
          const SizedBox(height: 56),
          const _SectionTitle(
            'A CONSIDERATE ZIYARAT',
            'Small gestures. A peaceful atmosphere.',
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: guideKey,
            child: const TwoColumn(
              main: GuidelinesCard(),
              aside: LocationCard(),
            ),
          ),
          const SizedBox(height: 56),
          TwoColumn(
            main: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'BEFORE YOU SET OUT',
                  'Make room for a meaningful visit.',
                ),
                SizedBox(height: 18),
                AppText(
                  'Take a moment to review your reservation before travelling to Keekkott Sayyid Attakoya Thangal Maqam. Keep your booking details accessible, allow time for the journey and follow the guidance of the staff when you arrive.',
                ),
                SizedBox(height: 16),
                InfoLine(
                  Icons.family_restroom_outlined,
                  'Visiting with family',
                  'Check that the visitors included in your reservation are correct. Stay together and be mindful of children and older companions.',
                ),
                SizedBox(height: 16),
                InfoLine(
                  Icons.photo_camera_outlined,
                  'Photography & privacy',
                  'Ask staff before taking photographs. Respect other visitors and any restrictions within the Maqam.',
                ),
              ],
            ),
            aside: KeyedSubtree(
              key: questionsKey,
              child: const _VisitQuestions(),
            ),
          ),
          const SizedBox(height: 64),
          HomeFooter(onVideos: () => reveal(videosKey)),
        ],
      ),
    );
  }
}

class _MaqamHero extends StatelessWidget {
  const _MaqamHero();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/brand/maqam-hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(
                        0xFF082D25,
                      ).withValues(alpha: compact ? .93 : .96),
                      const Color(
                        0xFF082D25,
                      ).withValues(alpha: compact ? .72 : .16),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 24 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: .7),
                      border: Border.all(
                        color: AppColors.mintStrong.withValues(alpha: .3),
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const AppText(
                      'KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
                      style: TextStyle(
                        color: AppColors.mintStrong,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: AppText(
                      'A peaceful place.\nA heartfelt visit.',
                      style: TextStyle(
                        fontFamily: 'Newsreader',
                        fontSize: compact ? 32 : 44,
                        height: 1.12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AppText.rich(
                      const TextSpan(
                        children: [
                          TextSpan(text: 'Plan for a visit with '),
                          TextSpan(
                            text: 'Mr. Sayyid Ali Noufal Thangal Al-Aidrose',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                ' Keekkott for your spiritual advice and dua.',
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: const Color(0xFFE7EEE7),
                        fontSize: compact ? 14 : 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/book'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mintStrong,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                          foregroundColor: AppColors.emerald,
                        ),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const AppText('Book a visit'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/information'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                          side: const BorderSide(color: Color(0xFFB7C9BE)),
                        ),
                        child: const AppText('Visitor guide'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.secondary),
                  const SizedBox(height: 8),
                  const AppText(
                    'CHAVAKKAD  /  KERALA  /  INDIA',
                    style: TextStyle(
                      color: AppColors.mintStrong,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Oil painting inspired by the Keekkott Sayyid Attakoya Thangal Maqam photograph',
                    style: TextStyle(color: Color(0xFFD9E6DF), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.eyebrow, this.title);
  final String eyebrow, title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText(
        eyebrow,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 14),
      Semantics(
        header: true,
        child: AppText(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
    ],
  );
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 550
          ? 1
          : constraints.maxWidth < 900
          ? 2
          : children.length;
      return Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 18) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}

class _VisitStep extends StatelessWidget {
  const _VisitStep(this.number, this.title, this.description);
  final String number, title, description;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: AppText(
            number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ),
        const SizedBox(height: 20),
        AppText(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AppText(description),
      ],
    ),
  );
}

class _VisitQuestions extends StatelessWidget {
  const _VisitQuestions();
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Questions before you visit',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        for (final item in const [
          (
            'How do I reserve a visit?',
            'Choose Book a visit, select an available date and time, and follow the steps to verify your mobile number and confirm your visitor details.',
          ),
          (
            'Where can I find my entry pass?',
            'Sign in with the mobile number used for your reservation and open My Bookings. Your confirmed booking contains your QR pass and token details.',
          ),
          (
            'What if my plans change?',
            'Open My Bookings to check whether your booking is eligible for cancellation. If it is, cancel it there before making another reservation.',
          ),
          (
            'Which times are available?',
            'The booking calendar shows the latest available slots and closures. Times are shown in India Standard Time. Check availability before travelling.',
          ),
          (
            'Who can help with my visit?',
            'Open Visitor Information for directions and the contact details supplied by the Maqam administration. Ask staff about access needs before your journey.',
          ),
        ])
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 20),
            title: AppText(
              item.$1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            children: [
              Align(alignment: Alignment.centerLeft, child: AppText(item.$2)),
            ],
          ),
      ],
    ),
  );
}

class _LiveAvailability extends ConsumerWidget {
  const _LiveAvailability(this.config);
  final BookingConfiguration config;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = config.dates();
    if (!config.bookingEnabled || dates.isEmpty) {
      return const EmptyState(
        title: 'Bookings are currently paused',
        detail: 'Please check again soon.',
      );
    }
    final closed = ref.watch(closedDaysProvider).asData?.value ?? <String>{};
    final day = dates.firstWhere(
      (d) => !closed.contains(d),
      orElse: () => dates.first,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SurfaceCard(
          padding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      'Plan your visit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              AppText(
                '${VisitClock.dayLabel(day)} · ${config.hoursForDate(day)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              AsyncPanel(
                value: ref.watch(availabilityProvider(day)),
                onRetry: () => ref.invalidate(availabilityProvider(day)),
                builder: (a) {
                  final available = (a.closed ? <VisitSlot>[] : a.slots)
                      .where((s) => s.status == SlotStatus.available)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        '${available.length} available time slots',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (a.closed) AppText(a.reason),
                      if (available.isEmpty && !a.closed)
                        const AppText(
                          'Choose another date to find an available time.',
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: available
                            .take(3)
                            .map(
                              (s) => Chip(
                                visualDensity: VisualDensity.compact,
                                label: AppText(
                                  VisitClock.timeLabel(s.startTime),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/book'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const AppText('Choose a time'),
              ),
              const SizedBox(height: 8),
              const AppText(
                'Availability updates every 20 seconds.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeaturedVideo extends StatelessWidget {
  const _HomeFeaturedVideo();

  static const _videoId = 'xrsTvpbTsO0';
  static const _videoUrl = 'https://www.youtube.com/watch?v=$_videoId';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'A GLIMPSE OF KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
            style: TextStyle(
              color: AppColors.emerald,
              letterSpacing: 1.8,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          AppText(
            'A quiet moment before your visit.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const AppText(
            'കീക്കോട്ട് സയ്യിദ് ആറ്റക്കോയ തങ്ങൾ മഖാം',
            style: TextStyle(
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          AppText.rich(
            const TextSpan(
              children: [
                TextSpan(
                  text: 'Discover Keekkott Sayyid Attakoya Thangal Maqam. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text:
                      'Take a glimpse of the Maqam and its green surroundings through our channel’s featured video. A moment to pause, reflect and feel connected before your journey.',
                ),
              ],
            ),
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.65,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const AppText(
            'Planning a ziyarat? Check available visit times, reserve your slot and keep your booking pass ready before travelling.',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.65,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(_videoUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const AppText('Watch the full video with sound'),
          ),
        ],
      );
      final video = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child: youtubePlayer(
                  _videoId,
                  autoplay: true,
                  controls: false,
                  loop: true,
                  mute: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const AppText(
            'Keekkott Bungalow Online · Silent video preview',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      );
      return Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: video,
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 32),
                  SizedBox(width: constraints.maxWidth * .38, child: video),
                ],
              ),
      );
    },
  );
}
