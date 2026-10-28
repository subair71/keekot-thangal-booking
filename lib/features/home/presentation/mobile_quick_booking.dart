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

class MobileVisitSelection {
  const MobileVisitSelection({this.date, this.slotId, this.visitors = 2});
  final String? date, slotId;
  final int visitors;
}

class MobileVisitController extends Notifier<MobileVisitSelection> {
  @override
  MobileVisitSelection build() => const MobileVisitSelection();
  void date(String value) =>
      state = MobileVisitSelection(date: value, visitors: state.visitors);
  void slot(String day, String id) => state = MobileVisitSelection(
    date: day,
    slotId: id,
    visitors: state.visitors,
  );
  void visitors(int count) => state = MobileVisitSelection(
    date: state.date,
    slotId: state.slotId,
    visitors: count,
  );
}

final mobileVisitSelectionProvider =
    NotifierProvider<MobileVisitController, MobileVisitSelection>(
      MobileVisitController.new,
    );

class MobileQuickBooking extends ConsumerWidget {
  const MobileQuickBooking({super.key, required this.config});
  final BookingConfiguration config;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobileVisitSelectionProvider);
    final controller = ref.read(mobileVisitSelectionProvider.notifier);
    final count = state.visitors.clamp(1, config.maxVisitorsPerBooking);
    final dates = config.dates();
    if (!config.bookingEnabled || dates.isEmpty) {
      return const EmptyState(
        title: 'Bookings are currently paused',
        detail: 'Please check again soon.',
      );
    }
    return SurfaceCard(
      color: AppColors.cream,
      borderColor: AppColors.outline,
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                color: AppColors.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Reserve a Visit Slot',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 21,
                        height: 1.3,
                        color: AppColors.primary,
                      ),
                    ),
                    if (AppLanguage.of(context) == 'ml')
                      const AppText(
                        'സന്ദർശന സമയം തിരഞ്ഞെടുക്കുക',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Malayalam',
                          fontSize: 10,
                          height: 1.7,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncPanel(
            value: ref.watch(closedDaysProvider),
            onRetry: () => ref.invalidate(closedDaysProvider),
            builder: (closed) {
              final open = dates.where((d) => !closed.contains(d)).toList();
              if (open.isEmpty) {
                return const EmptyState(
                  title: 'No available dates in this booking window.',
                );
              }
              final day = open.contains(state.date) ? state.date! : open.first;
              final current = ref.watch(availabilityProvider(day));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: AppText(
                          'Select date',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Flexible(
                        child: AppText(
                          DateFormat(
                            'MMMM yyyy',
                            AppLanguage.of(context),
                          ).format(DateTime.parse(day)),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in dates)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: SizedBox(
                              width:
                                  56 *
                                  MediaQuery.textScalerOf(
                                    context,
                                  ).scale(1).clamp(1, 1.8),
                              child: Semantics(
                                selected: d == day,
                                label: VisitClock.dayLabel(d),
                                child: TextButton(
                                  key: ValueKey('mobile-date-$d'),
                                  onPressed: closed.contains(d)
                                      ? null
                                      : () => controller.date(d),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 10,
                                    ),
                                    backgroundColor: d == day
                                        ? AppColors.emerald
                                        : AppColors.disabled,
                                    foregroundColor: d == day
                                        ? AppColors.ivory
                                        : AppColors.primary,
                                  ),
                                  child: Column(
                                    children: [
                                      AppText(
                                        DateFormat(
                                          'EEE',
                                          AppLanguage.of(context),
                                        ).format(DateTime.parse(d)),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        '${DateTime.parse(d).day}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      AppText(
                                        closed.contains(d)
                                            ? 'Closed'
                                            : d == VisitClock.today()
                                            ? 'Today'
                                            : 'Select',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: d == day
                                              ? AppColors.mintStrong
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      AppText(
                        '${tr(context, 'Available Time Slots')} (${config.slotDurationMinutes} ${tr(context, 'Mins')})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppText(
                        config.hoursForDate(day),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      if (current.hasValue && !current.hasError)
                        const AppText(
                          '● Live',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.available,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AsyncPanel<Availability>(
                    value: current,
                    onRetry: () => ref.invalidate(availabilityProvider(day)),
                    builder: (availability) {
                      final slots = availability.closed
                          ? <VisitSlot>[]
                          : availability.slots;
                      final selected = slots
                          .where(
                            (s) => s.id == state.slotId && s.accepts(count),
                          )
                          .firstOrNull;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (availability.closed) ...[
                            const AppText('No visits on this date'),
                            if (availability.reason.isNotEmpty)
                              AppText(availability.reason),
                          ] else if (slots.isEmpty)
                            const AppText(
                              'Choose another date to find an available time.',
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 136),
                              child: SingleChildScrollView(
                                primary: false,
                                child: LayoutBuilder(
                                  builder: (context, c) {
                                    final columns =
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(1) >
                                            1.3
                                        ? 1
                                        : 2;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final slot in slots)
                                          SizedBox(
                                            width:
                                                (c.maxWidth -
                                                    (columns - 1) * 8) /
                                                columns,
                                            child: _Slot(
                                              slot: slot,
                                              count: count,
                                              selected: selected?.id == slot.id,
                                              onTap: () =>
                                                  controller.slot(day, slot.id),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.disabled,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const AppText(
                                        'Visitors',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      AppText(
                                        '$count ${tr(context, count == 1
                                            ? 'Person (Individual)'
                                            : count <= 3
                                            ? 'Persons (Family)'
                                            : 'Persons (Group)')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: tr(context, 'Remove one visitor'),
                                  onPressed: count <= 1
                                      ? null
                                      : () => controller.visitors(count - 1),
                                  icon: const Icon(Icons.remove, size: 18),
                                ),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: tr(context, 'Add one visitor'),
                                  onPressed:
                                      count >= config.maxVisitorsPerBooking
                                      ? null
                                      : () => controller.visitors(count + 1),
                                  icon: const Icon(Icons.add, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (state.slotId != null &&
                              selected == null &&
                              !availability.closed)
                            const AppText(
                              'Your selected time is no longer available for this group. Choose another time.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
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
                            icon: const Icon(
                              Icons.how_to_reg_outlined,
                              size: 18,
                            ),
                            label: const AppText(
                              'Proceed to Instant Verification',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const AppText(
                            '100% Free Booking · No fees required at any stage',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
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
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final VisitSlot slot;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final enabled = slot.accepts(count);
    final limited = enabled && slot.remaining < slot.capacity;
    final status = switch (slot.status) {
      SlotStatus.full => 'Fully booked',
      SlotStatus.blocked => 'Closed',
      SlotStatus.past => 'Time passed',
      SlotStatus.available =>
        enabled
            ? limited
                  ? '${slot.remaining} places left'
                  : 'Open'
            : 'Not enough places for this group',
    };
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(9),
          backgroundColor: selected
              ? AppColors.emerald
              : enabled
              ? AppColors.ivory
              : AppColors.disabled,
          foregroundColor: selected ? AppColors.ivory : AppColors.primary,
          side: BorderSide(
            color: selected ? AppColors.brass : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    VisitClock.timeLabel(slot.startTime),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.mintStrong,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AppText(
              status,
              style: TextStyle(
                fontSize: 10,
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
        ),
      ),
    );
  }
}
