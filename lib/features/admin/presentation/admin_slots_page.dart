import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';

class AdminSlots extends ConsumerStatefulWidget {
  const AdminSlots({super.key});
  @override
  ConsumerState<AdminSlots> createState() => _AdminSlotsState();
}

class _AdminSlotsState extends ConsumerState<AdminSlots> {
  final form = GlobalKey<FormState>(),
      reason = TextEditingController(),
      capacity = TextEditingController();
  String day = VisitClock.today(), from = '07:00', until = '07:30';
  bool blocked = true, wholeDay = false, busy = false;
  @override
  void dispose() {
    reason.dispose();
    capacity.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).updateSlots({
        'visitDate': day,
        'startTime': from,
        'endTime': until,
        'blocked': blocked,
        'wholeDay': wholeDay,
        'reason': reason.text.trim(),
        if (capacity.text.trim().isNotEmpty)
          'capacity': int.parse(capacity.text.trim()),
      });
      ref.invalidate(availabilityProvider(day));
      ref.invalidate(adminDashboardProvider);
      if (mounted) showMessage(context, 'The schedule has been updated.');
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TwoColumn(
    main: SurfaceCard(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage slots & closures',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.parse(VisitClock.today());
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(day),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 30)),
                );
                if (d != null) setState(() => day = VisitClock.dayKey(d));
              },
              icon: const Icon(Icons.calendar_month),
              label: Text(VisitClock.dayLabel(day)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Whole day'),
              value: wholeDay,
              onChanged: (v) => setState(() => wholeDay = v),
            ),
            if (!wholeDay)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: from,
                      onChanged: (v) => from = v,
                      decoration: const InputDecoration(
                        labelText: 'From (24h)',
                      ),
                      validator: (v) =>
                          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                          ? null
                          : 'Use HH:mm',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: until,
                      onChanged: (v) => until = v,
                      decoration: const InputDecoration(
                        labelText: 'Until (24h)',
                      ),
                      validator: (v) =>
                          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                          ? null
                          : 'Use HH:mm',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Block')),
                ButtonSegment(value: false, label: Text('Open')),
              ],
              selected: {blocked},
              onSelectionChanged: (s) => setState(() => blocked = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: reason,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Prayer time, maintenance, holiday…',
              ),
              validator: (v) => blocked && (v == null || v.trim().isEmpty)
                  ? 'Enter a reason visitors can understand.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity (optional)',
                helperText: 'Leave empty to keep each slot’s capacity.',
              ),
              validator: (v) =>
                  v == null ||
                      v.isEmpty ||
                      ((int.tryParse(v) ?? 0) >= 1 &&
                          (int.tryParse(v) ?? 0) <= 500)
                  ? null
                  : 'Enter 1–500.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Update slots'),
            ),
          ],
        ),
      ),
    ),
    aside: const SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before changing the schedule',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          Text(
            'Changes apply to complete slots within the selected range. Choose the same start and end as a single slot to edit just that period.',
          ),
          SizedBox(height: 16),
          Text(
            'Blocking stops new confirmations. Existing confirmed bookings remain valid; cancel affected bookings separately if visits cannot take place.',
          ),
          SizedBox(height: 16),
          Text(
            'Capacity cannot be reduced below confirmed visitors and active holds. Reopen a whole-day closure before reopening individual slots on that date.',
          ),
        ],
      ),
    ),
  );
}
