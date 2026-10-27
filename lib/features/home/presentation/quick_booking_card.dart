import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../../booking/domain/booking_models.dart';

/// A presentation of the same live availability and draft used by /book.
/// Authentication, holds and all booking enforcement remain in confirmation.
class QuickBookingCard extends ConsumerStatefulWidget {
  const QuickBookingCard({super.key, required this.config});
  final BookingConfiguration config;

  @override
  ConsumerState<QuickBookingCard> createState() => _QuickBookingCardState();
}

class _QuickBookingCardState extends ConsumerState<QuickBookingCard> {
  String? date, slotId;
  int visitors = 1;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final dates = config.dates();
    if (!config.bookingEnabled || dates.isEmpty) {
      return const EmptyState(
        title: 'Bookings are currently paused',
        detail: 'Please check again soon.',
      );
    }
    final count = visitors.clamp(1, config.maxVisitorsPerBooking);
    return SurfaceCard(
      borderColor: AppColors.brass,
      color: AppColors.ivory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.mintStrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  'Plan your visit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          AsyncPanel<Set<String>>(
            value: ref.watch(closedDaysProvider),
            onRetry: () => ref.invalidate(closedDaysProvider),
            builder: (closed) {
              final open = dates.where((d) => !closed.contains(d)).toList();
              if (open.isEmpty) {
                return const EmptyState(
                  title: 'No available dates in this booking window.',
                );
              }
              final day = open.contains(date) ? date! : open.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: AppText(
                          'Select date',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      AppText(
                        DateFormat(
                          'MMM yyyy',
                          AppLanguage.of(context),
                        ).format(DateTime.parse(day)),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('quick-date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(day),
                        firstDate: DateTime.parse(dates.first),
                        lastDate: DateTime.parse(dates.last),
                        selectableDayPredicate: (d) =>
                            open.contains(VisitClock.dayKey(d)),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          date = VisitClock.dayKey(picked);
                          slotId = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: AppText(VisitClock.dayLabel(day)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          config.hoursForDate(day),
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          '${config.slotDurationMinutes} minutes · India time',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AppText(
                    'Number of visitors',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: tr(context, 'Remove one visitor'),
                        onPressed: count <= 1
                            ? null
                            : () => setState(() => visitors = count - 1),
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: AppText(
                            '$count',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: tr(context, 'Add one visitor'),
                        onPressed: count >= config.maxVisitorsPerBooking
                            ? null
                            : () => setState(() => visitors = count + 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AsyncPanel<Availability>(
                    value: ref.watch(availabilityProvider(day)),
                    onRetry: () => ref.invalidate(availabilityProvider(day)),
                    builder: (availability) {
                      final slots = availability.closed
                          ? <VisitSlot>[]
                          : availability.slots;
                      final selected = slots
                          .where((s) => s.id == slotId && s.accepts(count))
                          .firstOrNull;
                      final available = slots
                          .where((s) => s.accepts(count))
                          .length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: AppText(
                              availability.closed
                                  ? 'No visits on this date'
                                  : '$available available time slots',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: available == 0
                                    ? AppColors.error
                                    : AppColors.available,
                              ),
                            ),
                          ),
                          if (availability.closed &&
                              availability.reason.isNotEmpty)
                            AppText(availability.reason),
                          if (available == 0 && !availability.closed)
                            const AppText(
                              'Choose another date to find an available time.',
                            ),
                          const SizedBox(height: 12),
                          if (slots.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 236),
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  primary: false,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final columns =
                                          constraints.maxWidth >= 290 &&
                                              MediaQuery.textScalerOf(
                                                    context,
                                                  ).scale(1) <=
                                                  1.3
                                          ? 2
                                          : 1;
                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final slot in slots)
                                            SizedBox(
                                              width:
                                                  (constraints.maxWidth -
                                                      (columns - 1) * 8) /
                                                  columns,
                                              child: _QuickSlot(
                                                slot: slot,
                                                visitors: count,
                                                selected:
                                                    selected?.id == slot.id,
                                                onTap: () => setState(
                                                  () => slotId = slot.id,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (slotId != null &&
                              selected == null &&
                              !availability.closed)
                            const AppText(
                              'Your selected time is no longer available for this group. Choose another time.',
                            ),
                          if (selected != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppText(
                                selected.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            key: const ValueKey('quick-continue'),
                            onPressed: selected == null
                                ? null
                                : () {
                                    ref
                                        .read(draftProvider.notifier)
                                        .select(selected, count);
                                    context.go('/book/confirmation');
                                  },
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const AppText('Continue'),
                          ),
                        ],
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => context.go('/book'),
                    child: const AppText('View all availability'),
                  ),
                  const AppText(
                    'Availability updates every 20 seconds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickSlot extends StatelessWidget {
  const _QuickSlot({
    required this.slot,
    required this.visitors,
    required this.selected,
    required this.onTap,
  });
  final VisitSlot slot;
  final int visitors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = slot.accepts(visitors);
    final limited = enabled && slot.remaining < slot.capacity;
    final label = switch (slot.status) {
      SlotStatus.available =>
        enabled
            ? '${slot.remaining} places left'
            : 'Not enough places for this group',
      SlotStatus.full => 'Fully booked',
      SlotStatus.blocked => slot.reason.isEmpty ? 'Unavailable' : slot.reason,
      SlotStatus.past => '',
    };
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(10),
          backgroundColor: selected
              ? AppColors.emerald
              : enabled
              ? AppColors.white
              : AppColors.disabled,
          foregroundColor: selected ? AppColors.ivory : AppColors.emerald,
          side: BorderSide(
            color: selected
                ? AppColors.brass
                : enabled
                ? AppColors.secondary
                : AppColors.outline,
          ),
        ),
        child: Column(
          children: [
            AppText(
              VisitClock.timeLabel(slot.startTime),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppText(
                limited
                    ? '${tr(context, 'Limited')} · ${tr(context, label)}'
                    : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? AppColors.mintStrong
                      : limited
                      ? AppColors.limitedText
                      : enabled
                      ? AppColors.available
                      : AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
