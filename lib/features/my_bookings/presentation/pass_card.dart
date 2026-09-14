import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';
import '../data/pass_download.dart';

class PassCard extends ConsumerStatefulWidget {
  const PassCard({super.key, required this.booking});
  final VisitBooking booking;
  @override
  ConsumerState<PassCard> createState() => _PassCardState();
}

class _PassCardState extends ConsumerState<PassCard> {
  bool busy = false;
  Future<void> cancel() async {
    final yes = await confirmDialog(
      context,
      'Cancel this visit?',
      'Your places will become available to other visitors.',
      confirmLabel: 'Cancel visit',
    );
    if (!yes || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancel(widget.booking.id, 'Cancelled by visitor');
      if (mounted) showMessage(context, 'Your booking has been cancelled.');
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge(
                b.status.toUpperCase(),
                danger: b.status == 'cancelled',
                neutral: b.status == 'expired',
              ),
              const Spacer(),
              const Emblem(size: 44),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'VISITOR TOKEN',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          SelectableText(
            b.reference,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: 24),
          const InfoLine(
            Icons.location_on_outlined,
            'Keekot Thangal Maqam',
            'Chavakkad, Kerala',
          ),
          const SizedBox(height: 22),
          InfoLine(
            Icons.calendar_today_outlined,
            VisitClock.dayLabel(b.visitDate),
            '${b.timeLabel}\nIndia Standard Time',
          ),
          const SizedBox(height: 22),
          InfoLine(
            Icons.person_outline,
            b.visitorName,
            '${b.phoneMasked} · ${b.visitors} ${b.visitors == 1 ? 'visitor' : 'visitors'}',
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 24),
          if (b.upcoming) ...[
            Center(
              child: Semantics(
                label: 'Private QR pass for entry staff',
                image: true,
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: b.qrToken,
                    size: 210,
                    backgroundColor: AppColors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.emerald,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Show this pass to entry staff',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await PassDownload.download(b);
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, failureMessage(e));
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download pass (PDF)'),
            ),
          ] else
            const Text(
              'This pass is no longer valid for entry.',
              textAlign: TextAlign.center,
            ),
          if (b.canCancel) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: busy ? null : cancel,
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel booking'),
            ),
          ],
        ],
      ),
    );
  }
}
