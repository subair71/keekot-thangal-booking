import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import 'quick_booking_card.dart';
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
      width: 1280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availability = AsyncPanel(
                value: config,
                onRetry: () => ref.invalidate(configurationProvider),
                builder: (c) => QuickBookingCard(config: c),
              );
              final summary = AsyncPanel(
                value: config,
                onRetry: () => ref.invalidate(configurationProvider),
                builder: (c) => SurfaceCard(
                  color: AppColors.cream,
                  padding: 24,
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
              );
              if (constraints.maxWidth < 1050) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MaqamHero(),
                    const SizedBox(height: 20),
                    availability,
                    const SizedBox(height: 20),
                    summary,
                  ],
                );
              }
              return StickyAsideLayout(
                main: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MaqamHero(),
                    const SizedBox(height: 20),
                    summary,
                  ],
                ),
                aside: availability,
              );
            },
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 24 : 36,
            ),
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 32),
                  const AppText(
                    'Keekkott Bungalow',
                    style: TextStyle(
                      color: AppColors.ivory,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: AppText(
                      'A peaceful place.\nA heartfelt visit.',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: compact ? 34 : 48,
                        height: 1.22,
                        color: AppColors.mintStrong,
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
                          textStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                          ),
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
                          textStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                          ),
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
      Container(
        width: 30,
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: AppColors.goldText,
      ),
      AppText(
        eyebrow,
        style: const TextStyle(
          color: AppColors.goldText,
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
            color: AppColors.emerald,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: AppText(
            number,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.mintStrong,
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

class _HomeFeaturedVideo extends StatelessWidget {
  const _HomeFeaturedVideo();

  static const _videoId = 'xrsTvpbTsO0';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 800;
      final ml = AppLanguage.of(context) == 'ml';
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.goldText,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            ml ? 'മഖാമിനെ അടുത്തറിയാം' : 'EXPLORE THE MAQAM',
            style: const TextStyle(
              color: AppColors.emerald,
              letterSpacing: 1.6,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: AppText(
              ml
                  ? 'സന്ദർശനത്തിന് മുമ്പ് ഒരു ശാന്ത നിമിഷം.'
                  : 'A quiet moment before your visit.',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: compact ? 26 : 34,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            ml
                ? 'ചാവക്കാട്ടെ കീക്കോട്ട് സയ്യിദ് ആറ്റക്കോയ തങ്ങൾ മഖാമും അതിന്റെ ശാന്തമായ പരിസരവും അടുത്തറിയാം.'
                : 'Discover the Maqam and its peaceful surroundings in Chavakkad. A moment for reflection before your journey.',
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.65,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AppText(
                  ml ? 'ചാവക്കാട്, കേരളം' : 'Chavakkad, Kerala',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      final video = ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: AppColors.emerald,
            child: youtubePlayer(
              _videoId,
              autoplay: false,
              controls: true,
              loop: true,
              mute: true,
            ),
          ),
        ),
      );
      return Container(
        padding: EdgeInsets.all(compact ? 20 : 32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [video, const SizedBox(height: 24), content],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 4, child: content),
                  const SizedBox(width: 40),
                  Expanded(flex: 6, child: video),
                ],
              ),
      );
    },
  );
}
