import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import 'pass_card.dart';
import '../../notifications/presentation/notifications_page.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});
  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage> {
  bool past = false;
  @override
  Widget build(BuildContext context) => PageContainer(
    width: 1000,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'My bookings & passes',
          eyebrow: 'Your visits',
          subtitle: 'Everything you need for your next visit.',
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Upcoming')),
            ButtonSegment(value: true, label: Text('Past bookings')),
          ],
          selected: {past},
          onSelectionChanged: (s) => setState(() => past = s.first),
        ),
        const SizedBox(height: 24),
        AsyncPanel(
          value: ref.watch(myBookingsProvider),
          onRetry: () => ref.invalidate(myBookingsProvider),
          builder: (bookings) {
            final items = bookings
                .where((b) => past ? !b.upcoming : b.upcoming)
                .toList();
            if (items.isEmpty) {
              return EmptyState(
                title: past ? 'No past bookings' : 'No upcoming bookings',
                detail: 'Your visits will appear here.',
                action: FilledButton(
                  onPressed: () => context.go('/book'),
                  child: const Text('Book a visit'),
                ),
              );
            }
            return Column(
              children: [
                for (final b in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Text(
                                b.reference,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                              StatusBadge(
                                b.status.toUpperCase(),
                                danger: b.status == 'cancelled',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            VisitClock.dayLabel(b.visitDate),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('${b.timeLabel} · ${b.visitors} visitors'),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/pass/${b.id}'),
                            icon: const Icon(Icons.qr_code),
                            label: Text(
                              b.upcoming ? 'View pass' : 'View booking',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class PassPage extends ConsumerWidget {
  const PassPage({super.key, required this.id, this.success = false});
  final String id;
  final bool success;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageContainer(
    width: 660,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          success ? 'Your visit is confirmed' : 'Your visitor pass',
          eyebrow: success
              ? 'We look forward to welcoming you'
              : 'Keekot Thangal',
        ),
        AsyncPanel(
          value: ref.watch(bookingProvider(id)),
          onRetry: () => ref.invalidate(bookingProvider(id)),
          builder: (booking) => booking == null
              ? const EmptyState(title: 'Booking not found')
              : PassCard(booking: booking),
        ),
        if (success) ...[const SizedBox(height: 24), const NotificationOptIn()],
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => context.go('/my-bookings'),
          child: const Text('View all my bookings'),
        ),
      ],
    ),
  );
}
