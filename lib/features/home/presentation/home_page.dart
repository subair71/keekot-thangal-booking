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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 26),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: AppColors.gold, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assalamu alaikum. You are welcome here.',
                    style: TextStyle(color: AppColors.emerald),
                  ),
                ),
              ],
            ),
          ),
          TwoColumn(
            main: Container(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 24 : 40,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF163F35), Color(0xFF245F50)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Emblem(size: 52),
                      Text(
                        'ZIYARAT & VISITOR ENTRY',
                        style: TextStyle(
                          color: AppColors.mintStrong,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'A little planning.\nA peaceful visit.',
                    style:
                        (MediaQuery.sizeOf(context).width < 600
                                ? Theme.of(context).textTheme.headlineLarge
                                : Theme.of(context).textTheme.displayLarge)!
                            .copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Reserve your time at Keekkott Thangal Maqam, Chavakkad. Make space for quiet reflection, together.',
                    style: TextStyle(
                      color: Color(0xFFD9E6DF),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mintStrong,
                          foregroundColor: AppColors.emerald,
                        ),
                        onPressed: () => context.go('/book'),
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                        ),
                        label: const Text('Book a visit'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/my-bookings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: Color(0xFF799A89)),
                        ),
                        child: const Text('My bookings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFF4B7563)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.mintStrong,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chavakkad · Kerala · India',
                          style: TextStyle(
                            color: AppColors.mintStrong,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            aside: AsyncPanel(
              value: config,
              onRetry: () => ref.invalidate(configurationProvider),
              builder: (c) => _LiveAvailability(c),
            ),
          ),
          const SizedBox(height: 28),
          AsyncPanel(
            value: config,
            onRetry: () => ref.invalidate(configurationProvider),
            builder: (c) => LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                final items = [
                  InfoLine(Icons.schedule, 'Visiting hours', c.hours),
                  InfoLine(
                    Icons.hourglass_bottom_outlined,
                    'Visit duration',
                    '${c.slotDurationMinutes} minutes',
                  ),
                  const InfoLine(
                    Icons.location_on_outlined,
                    'Sacred Maqam',
                    'Chavakkad, Kerala',
                  ),
                  const InfoLine(
                    Icons.qr_code_2,
                    'Your entry pass',
                    'Keep your QR pass ready',
                  ),
                ];
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width:
                            (constraints.maxWidth - 16 * (columns - 1)) /
                            columns,
                        child: SurfaceCard(padding: 18, child: item),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          TwoColumn(main: const GuidelinesCard(), aside: const LocationCard()),
          const SizedBox(height: 44),
          Text(
            '“Enter with peace. Leave with tranquility.”',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Keekkott Thangal · Visit Booking\nAll visit times are in India Standard Time.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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
