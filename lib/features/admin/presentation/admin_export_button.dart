import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../data/booking_export.dart';
import '../data/export_download.dart';

class AdminExportButton extends ConsumerStatefulWidget {
  const AdminExportButton({super.key});
  @override
  ConsumerState<AdminExportButton> createState() => _AdminExportButtonState();
}

class _AdminExportButtonState extends ConsumerState<AdminExportButton> {
  bool busy = false;
  Future<void> download(String format) async {
    if (busy || ref.read(authProvider).asData?.value?.admin != true) return;
    final day = VisitClock.today();
    setState(() => busy = true);
    try {
      final bookings = await ref.read(adminRepositoryProvider)
          .exportBookingsForDate(day).timeout(const Duration(seconds: 30));
      final bytes = format == 'xlsx' ? BookingExport.excel(day, bookings)
          : await BookingExport.pdf(day, bookings);
      if (!mounted) return;
      await downloadExport(bytes, 'keekkott-bookings-$day.$format',
          format == 'xlsx' ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 'application/pdf');
      if (mounted) showMessage(context, 'Report prepared for $day (India time).');
    } on TimeoutException {
      if (mounted) showMessage(context, 'The report took too long to load. Please try again.');
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft,
    child: MenuAnchor(
      builder: (context, controller, child) => FilledButton.icon(
        onPressed: busy ? null : () { if (controller.isOpen) { controller.close(); } else { controller.open(); } },
        icon: const Icon(Icons.download_outlined),
        label: Text(busy ? 'Preparing report…' : 'Download today’s bookings')),
      menuChildren: [
        MenuItemButton(onPressed: busy ? null : () => download('xlsx'), child: const Text('Excel (.xlsx)')),
        MenuItemButton(onPressed: busy ? null : () => download('pdf'), child: const Text('PDF (.pdf)')),
      ],
    ));
}
