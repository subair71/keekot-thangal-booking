import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../domain/booking_models.dart';
import 'slot_card.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});
  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  String? date, selectedId;
  int visitors = 1;
  @override
  Widget build(BuildContext context) => PageContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Select your visit',
          eyebrow: 'A time for quiet reflection',
          subtitle: 'Choose a date, a time, and the number of visitors.',
        ),
        AsyncPanel(
          value: ref.watch(configurationProvider),
          onRetry: () => ref.invalidate(configurationProvider),
          builder: (config) {
            final dates = config.dates(),
                closed =
                    ref.watch(closedDaysProvider).asData?.value ?? <String>{};
            if (!config.bookingEnabled || dates.isEmpty)
              return const EmptyState(
                title: 'Bookings are currently paused',
                detail: 'Please check again soon.',
              );
            final day = dates.contains(date)
                ? date!
                : dates.firstWhere(
                    (d) => !closed.contains(d),
                    orElse: () => dates.first,
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        VisitClock.dayLabel(day),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final initial = dates.firstWhere(
                          (d) => !closed.contains(d),
                          orElse: () => dates.first,
                        );
                        if (closed.contains(initial)) {
                          showMessage(
                            context,
                            'No available dates in this booking window.',
                          );
                          return;
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(
                            closed.contains(day) ? initial : day,
                          ),
                          firstDate: DateTime.parse(dates.first),
                          lastDate: DateTime.parse(dates.last),
                          selectableDayPredicate: (d) =>
                              !closed.contains(VisitClock.dayKey(d)),
                        );
                        if (picked != null)
                          setState(() {
                            date = VisitClock.dayKey(picked);
                            selectedId = null;
                          });
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Calendar'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 105,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final d = dates[i],
                          dt = DateTime.parse(d),
                          selected = d == day;
                      return SizedBox(
                        width: 82,
                        child: Semantics(
                          selected: selected,
                          label: VisitClock.dayLabel(d),
                          child: OutlinedButton(
                            onPressed: closed.contains(d)
                                ? null
                                : () => setState(() {
                                    date = d;
                                    selectedId = null;
                                  }),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: selected
                                  ? AppColors.emerald
                                  : AppColors.white,
                              foregroundColor: selected
                                  ? AppColors.white
                                  : AppColors.emerald,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d == VisitClock.today()
                                      ? 'Today'
                                      : DateFormat('EEE').format(dt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${dt.day}',
                                  style: const TextStyle(
                                    fontFamily: 'Newsreader',
                                    fontSize: 30,
                                  ),
                                ),
                                Text(
                                  closed.contains(d)
                                      ? 'Closed'
                                      : DateFormat('MMM').format(dt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    StatusBadge('Available'),
                    StatusBadge('Full / past', neutral: true),
                    StatusBadge('Blocked', danger: true),
                  ],
                ),
                const SizedBox(height: 24),
                AsyncPanel(
                  value: ref.watch(availabilityProvider(day)),
                  onRetry: () => ref.invalidate(availabilityProvider(day)),
                  builder: (availability) {
                    final selected = availability.slots
                        .where((s) => s.id == selectedId && s.accepts(visitors))
                        .firstOrNull;
                    if (availability.closed)
                      return EmptyState(
                        title: 'No visits on this date',
                        detail: availability.reason,
                      );
                    final main = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SurfaceCard(
                          color: AppColors.mint,
                          padding: 18,
                          child: InfoLine(
                            Icons.spa_outlined,
                            'A peaceful visit for everyone',
                            'Please arrive ${config.arrivalMinutes} minutes early and keep your pass ready.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final period in [
                          ('Morning', '00:00', '12:00'),
                          ('Afternoon', '12:00', '16:00'),
                          ('Evening', '16:00', '24:00'),
                        ]) ...[
                          if (availability.slots.any(
                            (s) =>
                                s.startTime.compareTo(period.$2) >= 0 &&
                                s.startTime.compareTo(period.$3) < 0,
                          )) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                period.$1,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final slots = availability.slots
                                    .where(
                                      (s) =>
                                          s.startTime.compareTo(period.$2) >=
                                              0 &&
                                          s.startTime.compareTo(period.$3) < 0,
                                    )
                                    .toList();
                                final cols = constraints.maxWidth >= 640
                                    ? 3
                                    : 2;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final slot in slots)
                                      SizedBox(
                                        width:
                                            (constraints.maxWidth -
                                                12 * (cols - 1)) /
                                            cols,
                                        child: SlotCard(
                                          slot: slot,
                                          selected: selected?.id == slot.id,
                                          visitors: visitors,
                                          onSelect: () => setState(
                                            () => selectedId = slot.id,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 26),
                          ],
                        ],
                      ],
                    );
                    return TwoColumn(
                      main: main,
                      aside: SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Your visit',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            InfoLine(
                              Icons.schedule,
                              'Visiting hours',
                              config.hours,
                            ),
                            const SizedBox(height: 22),
                            InfoLine(
                              Icons.hourglass_empty,
                              'Duration',
                              '${config.slotDurationMinutes} minutes · India time',
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Number of visitors',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'Remove one visitor',
                                  onPressed: visitors <= 1
                                      ? null
                                      : () => setState(() => visitors--),
                                  icon: const Icon(Icons.remove),
                                ),
                                Expanded(
                                  child: Text(
                                    '$visitors',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton.filled(
                                  tooltip: 'Add one visitor',
                                  onPressed:
                                      visitors >=
                                              config.maxVisitorsPerBooking ||
                                          (selected != null &&
                                              visitors >= selected.remaining)
                                      ? null
                                      : () => setState(() => visitors++),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Up to ${config.maxVisitorsPerBooking} visitors per booking.',
                            ),
                            const SizedBox(height: 24),
                            Text(
                              selected == null
                                  ? 'Select an available time to continue.'
                                  : '${VisitClock.dayLabel(day)}\n${selected.label}',
                              style: const TextStyle(
                                color: AppColors.emerald,
                                height: 1.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: selected == null
                                  ? null
                                  : () {
                                      ref
                                          .read(draftProvider.notifier)
                                          .select(selected, visitors);
                                      context.go('/book/confirmation');
                                    },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue'),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'After mobile verification, your places are held for 5 minutes while you confirm.',
                              style: TextStyle(fontSize: 13, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
