import '../../../core/localization/app_language.dart';
import 'admin_date_hours.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';
import '../domain/schedule_changes.dart';

class AdminSlots extends ConsumerStatefulWidget {
  const AdminSlots({super.key});
  @override
  ConsumerState<AdminSlots> createState() => _AdminSlotsState();
}

class _AdminSlotsState extends ConsumerState<AdminSlots> {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController(), capacity = TextEditingController();
  final dates = <String>{VisitClock.today()}, selectedStarts = <String>{};
  bool blocked = true, wholeDay = false, busy = false;
  String? result;
  List<Map<String, dynamic>> failed = [];

  @override
  void dispose() {
    reason.dispose();
    capacity.dispose();
    super.dispose();
  }

  Future<void> addDates(bool range) async {
    final today = DateTime.parse(VisitClock.today());
    final last = today.add(const Duration(days: 30));
    if (range) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: today,
        lastDate: last,
      );
      if (picked == null || !mounted) return;
      setState(() {
        for (
          var d = picked.start;
          !d.isAfter(picked.end);
          d = DateTime(d.year, d.month, d.day + 1)
        ) {
          dates.add(VisitClock.dayKey(d));
        }
      });
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today,
        lastDate: last,
      );
      if (picked != null && mounted) {
        setState(() => dates.add(VisitClock.dayKey(picked)));
      }
    }
  }

  Future<void> apply(List<Map<String, dynamic>> changes) async {
    if (busy || changes.isEmpty) return;
    setState(() {
      busy = true;
      result = null;
      failed = [];
    });
    var completed = 0;
    final errors = <String>[];
    final failures = <Map<String, dynamic>>[];
    final repository = ref.read(adminRepositoryProvider);
    for (final change in changes) {
      try {
        await repository.updateSlots(change);
        completed++;
      } catch (e) {
        failures.add(change);
        final period = change['wholeDay'] == true
            ? 'whole day'
            : '${change['startTime']}–${change['endTime']}';
        errors.add('${change['visitDate']} · $period: ${failureMessage(e)}');
      }
    }
    if (!mounted) return;
    for (final change in changes) {
      ref.invalidate(availabilityProvider(change['visitDate'] as String));
    }
    ref.invalidate(closedDaysProvider);
    ref.invalidate(adminDashboardProvider);
    setState(() {
      busy = false;
      failed = failures;
      result = errors.isEmpty
          ? 'All selected dates and slots have been updated.'
          : '$completed of ${changes.length} schedule changes saved.\n${errors.join('\n')}';
    });
  }

  void save(List<VisitSlot> slots) {
    if (!form.currentState!.validate()) return;
    final changes = scheduleChanges(
      dates: dates,
      slots: slots,
      selectedStarts: selectedStarts,
      wholeDay: wholeDay,
      blocked: blocked,
      reason: reason.text,
      capacity: int.tryParse(capacity.text.trim()),
    );
    if (dates.isEmpty || changes.isEmpty) {
      showMessage(
        context,
        'Select at least one date and, unless blocking whole days, one time slot.',
      );
      return;
    }
    apply(changes);
  }

  @override
  Widget build(BuildContext context) => AsyncPanel(
    value: ref.watch(configurationProvider),
    onRetry: () => ref.invalidate(configurationProvider),
    builder: (config) {
      final slots = const SlotGenerator().generate(VisitClock.today(), config);
      final sortedDates = dates.toList()..sort();
      return TwoColumn(
        main: SurfaceCard(
          child: LocalizedForm(
            formKey: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  'Block dates & slots',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                AppText(
                  '1. Select dates (${dates.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => addDates(false),
                      icon: const Icon(Icons.calendar_today),
                      label: const AppText('Add a date'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => addDates(true),
                      icon: const Icon(Icons.date_range),
                      label: const AppText('Add date range'),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => setState(dates.clear),
                      child: const AppText('Clear dates'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in sortedDates)
                      InputChip(
                        label: AppText(VisitClock.dayLabel(day)),
                        onDeleted: busy
                            ? null
                            : () => setState(() => dates.remove(day)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Entire selected days'),
                  subtitle: const AppText(
                    'Apply to every slot on each selected date.',
                  ),
                  value: wholeDay,
                  onChanged: busy ? null : (v) => setState(() => wholeDay = v),
                ),
                if (!wholeDay) ...[
                  const SizedBox(height: 12),
                  AppText(
                    '2. Select time slots',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const AppText(
                    'Choose any combination. These slots apply to every selected date.',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(
                                () => selectedStarts.addAll(
                                  slots.map((s) => s.startTime),
                                ),
                              ),
                        child: const AppText('Select all slots'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(selectedStarts.clear),
                        child: const AppText('Clear slots'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in slots)
                        FilterChip(
                          label: AppText(slot.label),
                          selected: selectedStarts.contains(slot.startTime),
                          onSelected: busy
                              ? null
                              : (v) => setState(() {
                                  if (v) {
                                    selectedStarts.add(slot.startTime);
                                  } else {
                                    selectedStarts.remove(slot.startTime);
                                  }
                                }),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SanctuaryChoices<bool>(
                  options: const {true: 'Block', false: 'Reopen'},
                  value: blocked,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => blocked = value),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: reason,
                  enabled: !busy,
                  maxLength: 200,
                  decoration: InputDecoration(
                    label: AppText('Reason'),
                    hintText: tr(context, 'Prayer time, maintenance, holiday…'),
                  ),
                  validator: (v) => blocked && (v == null || v.trim().isEmpty)
                      ? tr(context, 'Enter a reason visitors can understand.')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacity,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: AppText('Capacity (optional)'),
                    helperText: tr(
                      context,
                      'Leave empty to keep each slot’s capacity.',
                    ),
                  ),
                  validator: (v) =>
                      v == null ||
                          v.trim().isEmpty ||
                          ((int.tryParse(v.trim()) ?? 0) >= 1 &&
                              (int.tryParse(v.trim()) ?? 0) <= 500)
                      ? null
                      : tr(context, 'Enter 1–500.'),
                ),
                const SizedBox(height: 24),
                AppText(
                  wholeDay
                      ? '${dates.length} entire days selected'
                      : '${dates.length} dates · ${slots.where((s) => selectedStarts.contains(s.startTime)).length} slots per date',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : () => save(slots),
                  child: AppText(
                    busy
                        ? 'Saving…'
                        : blocked
                        ? 'Block selected dates / slots'
                        : 'Reopen selected dates / slots',
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: AppText(result!)),
                  if (failed.isNotEmpty)
                    OutlinedButton(
                      onPressed: busy ? null : () => apply(List.of(failed)),
                      child: const AppText('Retry failed changes'),
                    ),
                ],
              ],
            ),
          ),
        ),
        aside: Column(
          children: [
            AdminDateHours(config: config),
            const SizedBox(height: 20),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Before changing the schedule',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  AppText(
                    'Add separate dates or a date range within the next 30 days. Select entire days, or choose multiple individual time slots.',
                  ),
                  SizedBox(height: 16),
                  AppText(
                    'Blocking prevents new confirmations. Existing confirmed bookings remain valid; cancel affected bookings separately if visits cannot take place.',
                  ),
                  SizedBox(height: 16),
                  AppText(
                    'Reopen a whole-day closure before reopening individual slots on that date. Capacity cannot be reduced below confirmed visitors and active holds.',
                  ),
                  SizedBox(height: 16),
                  AppText(
                    'Changes save in batches. If any fail, successful changes remain saved and you can retry only the failed changes.',
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
