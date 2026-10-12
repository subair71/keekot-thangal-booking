import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../../booking/domain/booking_models.dart';

class AdminDateHours extends ConsumerStatefulWidget {
  const AdminDateHours({super.key, required this.config});
  final BookingConfiguration config;
  @override
  ConsumerState<AdminDateHours> createState() => _AdminDateHoursState();
}

class _AdminDateHoursState extends ConsumerState<AdminDateHours> {
  String day = VisitClock.today();
  TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
  bool busy = false;
  String? message;
  String value(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  Future<void> pickTime(bool opening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? start : end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null && mounted)
      setState(() {
        if (opening) {
          start = picked;
        } else {
          end = picked;
        }
      });
  }

  Future<void> save(bool reset) async {
    final duration =
        end.hour * 60 + end.minute - start.hour * 60 - start.minute;
    if (!reset &&
        (duration <= 0 || duration % widget.config.slotDurationMinutes != 0)) {
      setState(
        () => message =
            'End time must be after start time and hours must contain complete ${widget.config.slotDurationMinutes}-minute slots.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ref.read(adminRepositoryProvider).setDateHours({
        'visitDate': day,
        'openingTime': value(start),
        'closingTime': value(end),
        'reset': reset,
      });
      ref.invalidate(availabilityProvider(day));
      ref.invalidate(configurationProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted)
        setState(
          () => message = reset
              ? 'Default hours restored for ${VisitClock.dayLabel(day)}.'
              : 'Hours saved for ${VisitClock.dayLabel(day)}.',
        );
    } catch (e) {
      if (mounted) setState(() => message = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.config.dateHours[day] as Map?;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hours for a specific date',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose a date, then set its visiting hours. For example: Wednesday, 8:00 AM–5:00 PM. Other dates keep their default hours.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(VisitClock.dayLabel(day)),
            onPressed: busy
                ? null
                : () async {
                    final today = DateTime.parse(VisitClock.today());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(day),
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 30)),
                    );
                    if (picked != null && mounted)
                      setState(() {
                        day = VisitClock.dayKey(picked);
                        message = null;
                        final saved = widget.config.dateHours[day] as Map?;
                        if (saved != null) {
                          final a = (saved['openingTime'] as String).split(':');
                          final b = (saved['closingTime'] as String).split(':');
                          start = TimeOfDay(
                            hour: int.parse(a[0]),
                            minute: int.parse(a[1]),
                          );
                          end = TimeOfDay(
                            hour: int.parse(b[0]),
                            minute: int.parse(b[1]),
                          );
                        }
                      });
                  },
          ),
          Text(
            hours == null
                ? 'Current hours: ${widget.config.hours} (default)'
                : 'Current hours: ${VisitClock.timeLabel(hours['openingTime'] as String)} – ${VisitClock.timeLabel(hours['closingTime'] as String)}',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy ? null : () => pickTime(true),
            child: Text('Start: ${VisitClock.timeLabel(value(start))}'),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => pickTime(false),
            child: Text('End: ${VisitClock.timeLabel(value(end))}'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : () => save(false),
            child: Text(busy ? 'Saving…' : 'Save date hours'),
          ),
          TextButton(
            onPressed: busy || hours == null ? null : () => save(true),
            child: const Text('Restore default hours'),
          ),
          const Text(
            'Whole-day closures and blocked slots still apply. Changes affecting confirmed visitors or active holds cannot be saved.',
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Text(message!)),
          ],
        ],
      ),
    );
  }
}
