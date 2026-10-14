import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../data/booking_export.dart' deferred as booking_export;
import '../data/export_download.dart';

class AdminExportButton extends ConsumerStatefulWidget {
  const AdminExportButton({super.key});
  @override
  ConsumerState<AdminExportButton> createState() => _AdminExportButtonState();
}

class _AdminExportButtonState extends ConsumerState<AdminExportButton> {
  bool busy = false;
  DateTime selectedDate = DateTime.parse(VisitClock.today());
  bool allDay = true;
  TimeOfDay start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 19, minute: 0);

  int minutes(TimeOfDay value) => value.hour * 60 + value.minute;
  String timeLabel(TimeOfDay value) => VisitClock.timeLabel(
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
  );

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (value != null && mounted) setState(() => selectedDate = value);
  }

  Future<void> pickTime(bool isStart) async {
    final value = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (value != null && mounted) {
      setState(() {
        if (isStart) {
          start = value;
        } else {
          end = value;
        }
      });
    }
  }

  Future<void> download(String format) async {
    if (busy || ref.read(authProvider).asData?.value?.admin != true) return;
    final day = VisitClock.dayKey(selectedDate);
    final from = allDay ? 0 : minutes(start);
    final until = allDay ? 1440 : minutes(end);
    if (from >= until) {
      showMessage(context, 'End time must be after start time.');
      return;
    }
    setState(() => busy = true);
    try {
      final bookings = await ref
          .read(adminRepositoryProvider)
          .exportBookingsForDate(day)
          .timeout(const Duration(seconds: 30));
      await booking_export.loadLibrary();
      final bytes = format == 'xlsx'
          ? booking_export.BookingExport.excel(
              day,
              bookings,
              startMinute: from,
              endMinute: until,
            )
          : await booking_export.BookingExport.pdf(
              day,
              bookings,
              startMinute: from,
              endMinute: until,
            );
      if (!mounted) return;
      await downloadExport(
        bytes,
        'keekkott-bookings-$day-${booking_export.BookingExport.filePeriod(from, until)}.$format',
        format == 'xlsx'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf',
      );
      if (mounted) {
        showMessage(context, 'Report prepared for $day (India time).');
      }
    } on TimeoutException {
      if (mounted) {
        showMessage(
          context,
          'The report took too long to load. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, failureMessage(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download bookings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Select a visit date and time frame. All times are India Standard Time (IST).',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : pickDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(VisitClock.dayLabel(VisitClock.dayKey(selectedDate))),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('All day'),
          value: allDay,
          onChanged: busy ? null : (value) => setState(() => allDay = value),
        ),
        if (!allDay) ...[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => pickTime(true),
                icon: const Icon(Icons.schedule),
                label: Text('Start: ${timeLabel(start)}'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => pickTime(false),
                icon: const Icon(Icons.schedule),
                label: Text('End: ${timeLabel(end)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Includes bookings starting at or after Start and before End, on the selected date.',
          ),
          if (minutes(start) >= minutes(end))
            Text(
              'End time must be after start time.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final format in ['pdf', 'xlsx'])
              FilledButton.icon(
                onPressed: busy || (!allDay && minutes(start) >= minutes(end))
                    ? null
                    : () => download(format),
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  format == 'pdf' ? 'Download PDF' : 'Download Excel',
                ),
              ),
          ],
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          const Text('Preparing report…'),
        ],
      ],
    ),
  );
}
