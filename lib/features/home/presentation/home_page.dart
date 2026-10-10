import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';
import '../../visitor_information/presentation/information_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    return PageContainer(
      width: 1400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MaqamHero(),
          const SizedBox(height: 24),
          AsyncPanel(
            value: config,
            onRetry: () => ref.invalidate(configurationProvider),
            builder: (c) => _FeatureGrid(
              children: [
                InfoLine(Icons.schedule_outlined, 'Visiting hours', c.hours),
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
          const SizedBox(height: 72),
          TwoColumn(
            main: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'WELCOME TO KEEKKOTT',
                  'A place for remembrance.\nA moment for yourself.',
                ),
                SizedBox(height: 20),
                Text(
                  'Assalamu alaikum. Welcome to Keekkott Thangal Maqam in Chavakkad, Kerala. Make time for ziyarat, dua and quiet reflection, and approach your visit with a spirit of respect and consideration.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.8,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'This visitor service helps you plan ahead: explore available dates, reserve a suitable time and keep your entry pass close at hand. Whether you are visiting on your own or accompanying family, a little preparation helps everyone arrive with peace of mind.',
                ),
                SizedBox(height: 28),
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
            aside: AsyncPanel(
              value: config,
              onRetry: () => ref.invalidate(configurationProvider),
              builder: (c) => _LiveAvailability(c),
            ),
          ),
          const SizedBox(height: 72),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'YOUR VISIT, SIMPLIFIED',
                  'Arrive prepared. Be fully present.',
                ),
                SizedBox(height: 30),
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
          const SizedBox(height: 72),
          const _SectionTitle(
            'A CONSIDERATE ZIYARAT',
            'Small gestures. A peaceful atmosphere.',
          ),
          const SizedBox(height: 24),
          const TwoColumn(main: GuidelinesCard(), aside: LocationCard()),
          const SizedBox(height: 72),
          const TwoColumn(
            main: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'BEFORE YOU SET OUT',
                  'Make room for a meaningful visit.',
                ),
                SizedBox(height: 18),
                Text(
                  'Take a moment to review your reservation before travelling to Keekkott Maqam. Keep your booking details accessible, allow time for the journey and follow the guidance of the staff when you arrive.',
                ),
                SizedBox(height: 24),
                InfoLine(
                  Icons.family_restroom_outlined,
                  'Visiting with family',
                  'Check that the visitors included in your reservation are correct. Stay together and be mindful of children and older companions.',
                ),
                SizedBox(height: 24),
                InfoLine(
                  Icons.photo_camera_outlined,
                  'Photography & privacy',
                  'Ask staff before taking photographs. Respect other visitors and any restrictions within the Maqam.',
                ),
              ],
            ),
            aside: _VisitQuestions(),
          ),
          const SizedBox(height: 64),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.spa_outlined,
                  color: AppColors.mintStrong,
                  size: 32,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your next visit begins with a little planning.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge!
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Find a suitable time and prepare for a peaceful ziyarat at Keekkott Maqam.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD9E6DF)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mintStrong,
                    foregroundColor: AppColors.emerald,
                  ),
                  onPressed: () => context.go('/book'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Plan my visit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),
          const Divider(),
          const SizedBox(height: 24),
          const Emblem(size: 64),
          const SizedBox(height: 12),
          Text(
            'Keekkott Thangal Maqam',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Ziyarat & visitor booking · Chavakkad, Kerala',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              TextButton(
                onPressed: () => context.go('/information'),
                child: const Text('Visitor information'),
              ),
              TextButton(
                onPressed: () => context.go('/my-bookings'),
                child: const Text('My bookings'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All visit times are in India Standard Time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
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
                      const Color(0xFF082D25)
                          .withValues(alpha: compact ? .93 : .96),
                      const Color(0xFF082D25)
                          .withValues(alpha: compact ? .72 : .16),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 26 : 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KEEKKOTT THANGAL MAQAM',
                    style: TextStyle(
                      color: AppColors.mintStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: compact ? 36 : 56),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Text(
                      'A peaceful place.\nA heartfelt visit.',
                      style: TextStyle(
                        fontFamily: 'Newsreader',
                        fontSize: compact ? 44 : 72,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: const Text(
                      'Pause for remembrance. Make time for dua. Plan your ziyarat at Keekkott Maqam, Chavakkad.',
                      style: TextStyle(
                        color: Color(0xFFE7EEE7),
                        fontSize: 17,
                        height: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/book'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mintStrong,
                          foregroundColor: AppColors.emerald,
                        ),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Book a visit'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/information'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFB7C9BE)),
                        ),
                        child: const Text('Visitor guide'),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 36 : 58),
                  const Text(
                    'CHAVAKKAD  /  KERALA  /  INDIA',
                    style: TextStyle(
                      color: AppColors.mintStrong,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Concept illustration · not a photograph of the Maqam',
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
      Text(
        eyebrow,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 14),
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
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
        spacing: 24,
        runSpacing: 28,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 24) / columns,
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        style: const TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 36,
          color: AppColors.gold,
        ),
      ),
      const SizedBox(height: 14),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Text(description),
    ],
  );
}

class _VisitQuestions extends StatelessWidget {
  const _VisitQuestions();
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
            title: Text(
              item.$1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(item.$2)),
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
    final day = dates.first;
    return SurfaceCard(
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
                child: Text(
                  'Plan your visit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const StatusBadge('Live'),
            ],
          ),
          const SizedBox(height: 16),
          Text(VisitClock.dayLabel(day)),
          const SizedBox(height: 20),
          AsyncPanel(
            value: ref.watch(availabilityProvider(day)),
            onRetry: () => ref.invalidate(availabilityProvider(day)),
            builder: (a) {
              final available = a.slots
                  .where((s) => s.status == SlotStatus.available)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${available.length}',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const Text('available time slots'),
                  const SizedBox(height: 20),
                  if (a.closed) Text(a.reason),
                  if (available.isEmpty && !a.closed)
                    const Text(
                      'Choose another date to find an available time.',
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: available
                        .take(4)
                        .map(
                          (s) => ActionChip(
                            label: Text(VisitClock.timeLabel(s.startTime)),
                            onPressed: () => context.go('/book'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => context.go('/book'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Choose a time'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Availability updates every 20 seconds.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
