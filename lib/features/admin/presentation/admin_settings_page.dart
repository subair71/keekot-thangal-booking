import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';

class AdminSettings extends ConsumerStatefulWidget {
  const AdminSettings({super.key});
  @override
  ConsumerState<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends ConsumerState<AdminSettings> {
  final form = GlobalKey<FormState>();
  bool loaded = false,
      busy = false,
      enabled = false,
      sameDay = true,
      reminders = true;
  final fields = <String, TextEditingController>{};
  static const definitions = {
    'openingTime': ('Opening time', '7:00 AM'),
    'closingTime': ('Closing time', '7:00 PM'),
    'slotDurationMinutes': ('Slot duration in minutes (10–120)', '30'),
    'bookingWindowDays': ('Booking window in days', '7'),
    'maxVisitorsPerBooking': ('Maximum visitors per booking', ''),
    'defaultSlotCapacity': ('Default slot capacity', ''),
    'arrivalMinutes': ('Arrival lead time in minutes', '10'),
    'reminderMinutes': ('Reminder lead time in minutes', '60'),
    'locationUrl': ('Official directions URL (optional)', ''),
    'contactPhone': ('Contact number with country code (optional)', ''),
  };
  @override
  void initState() {
    super.initState();
    for (final item in definitions.entries) {
      fields[item.key] = TextEditingController(text: item.value.$2);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final settings = <String, dynamic>{
        'timezone': 'Asia/Kolkata',
        'bookingEnabled': enabled,
        'allowSameDayBooking': sameDay,
        'reminderEnabled': reminders,
      };
      for (final e in fields.entries) {
        if (e.key == 'openingTime' || e.key == 'closingTime') {
          settings[e.key] = VisitClock.timeValue(e.value.text)!;
          continue;
        }
        settings[e.key] =
            [
              'openingTime',
              'closingTime',
              'locationUrl',
              'contactPhone',
            ].contains(e.key)
            ? e.value.text.trim()
            : int.parse(e.value.text);
      }
      await ref.read(adminRepositoryProvider).updateSettings(settings);
      ref.invalidate(configurationProvider);
      if (mounted) showMessage(context, 'Booking settings saved.');
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider).asData?.value;
    if (!loaded && config != null) {
      loaded = true;
      final data = config.toMap();
      for (final e in fields.entries) {
        e.value.text = e.key == 'openingTime' || e.key == 'closingTime'
            ? VisitClock.timeLabel('${data[e.key]}')
            : '${data[e.key]}';
      }
      enabled = config.bookingEnabled;
      sameDay = config.allowSameDayBooking;
      reminders = config.reminderEnabled;
    }
    return SurfaceCard(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Booking configuration',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Set capacity approved by the venue before opening bookings. Hours and duration cannot change while a future schedule is in use. Default capacity applies to new slots; use Slots & closures to update existing slots.',
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 700 ? 2 : 1;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final e in definitions.entries)
                      SizedBox(
                        width: (c.maxWidth - 20 * (cols - 1)) / cols,
                        child: TextFormField(
                          controller: fields[e.key],
                          decoration: InputDecoration(labelText: e.value.$1),
                          validator: (v) {
                            if ([
                              'locationUrl',
                              'contactPhone',
                            ].contains(e.key)) {
                              return null;
                            }
                            if (v == null || v.trim().isEmpty) {
                              return 'This value is required.';
                            }
                            if ([
                              'openingTime',
                              'closingTime',
                            ].contains(e.key)) {
                              return VisitClock.timeValue(v) != null
                                  ? null
                                  : 'Use h:mm AM/PM, for example 7:00 PM.';
                            }
                            if (e.key == 'slotDurationMinutes') {
                              final minutes = int.tryParse(v.trim());
                              if (minutes == null ||
                                  minutes < 10 ||
                                  minutes > 120) {
                                return 'Enter 10 to 120 whole minutes.';
                              }
                            }
                            return int.tryParse(v) == null
                                ? 'Enter a whole number.'
                                : null;
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open bookings to visitors'),
              value: enabled,
              onChanged: (v) => setState(() => enabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow same-day booking'),
              value: sameDay,
              onChanged: (v) => setState(() => sameDay = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Send visit reminders'),
              subtitle: const Text('Lead time changes apply to new bookings.'),
              value: reminders,
              onChanged: (v) => setState(() => reminders = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Save configuration'),
            ),
          ],
        ),
      ),
    );
  }
}
