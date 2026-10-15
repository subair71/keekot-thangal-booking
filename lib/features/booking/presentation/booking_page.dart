import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import 'slot_card.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});
  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  String? date, selectedId;
  int visitors = 1;
  String periodFilter = 'All times';
  final _continueKey = GlobalKey();
  final _continueFocus = FocusNode();

  @override
  void dispose() {
    _continueFocus.dispose();
    super.dispose();
  }

  void _selectSlot(String id) {
    setState(() => selectedId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || selectedId != id) return;
      final buttonContext = _continueKey.currentContext;
      if (buttonContext == null) return;
      final button = buttonContext.widget as FilledButton;
      if (button.onPressed == null) return;
      // Keep keyboard and screen-reader users on their chosen slot.
      if (MediaQuery.accessibleNavigationOf(context) ||
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional)
        return;
      _continueFocus.requestFocus();
      Scrollable.ensureVisible(
        buttonContext,
        alignment: 0.5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

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
        const BookingProgress(current: 0),
        const SizedBox(height: 24),
        AsyncPanel(
          value: ref.watch(configurationProvider),
          onRetry: () => ref.invalidate(configurationProvider),
          builder: (config) {
            final dates = config.dates(),
                closed =
                    ref.watch(closedDaysProvider).asData?.value ?? <String>{};
            if (!config.bookingEnabled || dates.isEmpty) {
              return const EmptyState(
                title: 'Bookings are currently paused',
                detail: 'Please check again soon.',
              );
            }
            final day = dates.contains(date)
                ? date!
                : dates.firstWhere(
                    (d) => !closed.contains(d),
                    orElse: () => dates.first,
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    AppText(
                      VisitClock.dayLabel(day),
                      style: Theme.of(context).textTheme.titleMedium,
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
                        if (picked != null && mounted) {
                          setState(() {
                            date = VisitClock.dayKey(picked);
                            selectedId = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const AppText('Calendar'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 125,
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
                                AppText(
                                  d == VisitClock.today()
                                      ? 'Today'
                                      : DateFormat('EEE', 'en').format(dt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                AppText(
                                  '${dt.day}',
                                  style: const TextStyle(
                                    fontFamily: 'Newsreader',
                                    fontSize: 30,
                                  ),
                                ),
                                AppText(
                                  closed.contains(d)
                                      ? 'Closed'
                                      : DateFormat('MMM', 'en').format(dt),
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
                    if (availability.closed) {
                      return EmptyState(
                        title: 'No visits on this date',
                        detail: availability.reason,
                      );
                    }
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
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in [
                              'All times',
                              'Morning',
                              'Afternoon',
                              'Evening',
                            ])
                              ChoiceChip(
                                label: AppText(label),
                                selected: periodFilter == label,
                                onSelected: (_) =>
                                    setState(() => periodFilter = label),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!availability.slots.any((s) => s.accepts(visitors)))
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: AppText(
                              'No available time for this group. Try another date or adjust the number of visitors.',
                            ),
                          ),
                        if (periodFilter != 'All times' &&
                            !availability.slots.any(
                              (s) => periodFilter == 'Morning'
                                  ? s.startTime.compareTo('12:00') < 0
                                  : periodFilter == 'Afternoon'
                                  ? s.startTime.compareTo('12:00') >= 0 &&
                                        s.startTime.compareTo('16:00') < 0
                                  : s.startTime.compareTo('16:00') >= 0,
                            ))
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: AppText(
                              'No scheduled slots in this period. Choose All times or another date.',
                            ),
                          ),
                        for (final period in [
                          ('Morning', '00:00', '12:00'),
                          ('Afternoon', '12:00', '16:00'),
                          ('Evening', '16:00', '24:00'),
                        ]) ...[
                          if ((periodFilter == 'All times' ||
                                  periodFilter == period.$1) &&
                              availability.slots.any(
                                (s) =>
                                    s.startTime.compareTo(period.$2) >= 0 &&
                                    s.startTime.compareTo(period.$3) < 0,
                              )) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AppText(
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
                                final scaledWidth =
                                    210 *
                                    MediaQuery.textScalerOf(context).scale(1);
                                final cols =
                                    ((constraints.maxWidth + 12) /
                                            (scaledWidth + 12))
                                        .floor()
                                        .clamp(1, 3);
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
                                          onSelect: () => _selectSlot(slot.id),
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
                      asideFirstOnMobile: true,
                      main: main,
                      aside: SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppText(
                              'Your visit',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            InfoLine(
                              Icons.schedule,
                              'Visiting hours',
                              config.hoursForDate(day),
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
                            const AppText(
                              'Number of visitors',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: tr(context, 'Remove one visitor'),
                                  onPressed: visitors <= 1
                                      ? null
                                      : () => setState(() => visitors--),
                                  icon: const Icon(Icons.remove),
                                ),
                                Expanded(
                                  child: AppText(
                                    '$visitors',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton.filled(
                                  tooltip: tr(context, 'Add one visitor'),
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
                            AppText(
                              'Up to ${config.maxVisitorsPerBooking} visitors per booking.',
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              liveRegion: true,
                              child: AppText(
                                selected == null
                                    ? (selectedId == null
                                          ? 'Select an available time to continue.'
                                          : 'Your selected time is no longer available for this group. Choose another time.')
                                    : '${VisitClock.dayLabel(day)}\n${selected.label}',
                                style: const TextStyle(
                                  color: AppColors.emerald,
                                  height: 1.7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              key: _continueKey,
                              focusNode: _continueFocus,
                              onPressed: selected == null
                                  ? null
                                  : () {
                                      ref
                                          .read(draftProvider.notifier)
                                          .select(selected, visitors);
                                      context.go('/book/confirmation');
                                    },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const AppText('Continue'),
                            ),
                            const SizedBox(height: 14),
                            const AppText(
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
