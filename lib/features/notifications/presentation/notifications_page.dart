import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageContainer(
    width: 800,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Notifications',
          subtitle: 'Booking confirmations, changes, and visit reminders.',
        ),
        const NotificationOptIn(),
        const SizedBox(height: 24),
        AsyncPanel(
          value: ref.watch(noticesProvider),
          onRetry: () => ref.invalidate(noticesProvider),
          builder: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'You are all caught up',
                  detail: 'New booking updates will appear here.',
                  icon: Icons.notifications_none,
                )
              : Column(
                  children: [
                    for (final n in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                n.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(n.body),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(notificationRepositoryProvider)
                                        .markRead(n.id);
                                  } catch (_) {
                                    /* Reading a booking remains possible if the read receipt fails. */
                                  }
                                  if (context.mounted)
                                    context.go('/booking/${n.bookingId}');
                                },
                                child: const Text('View booking'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class NotificationOptIn extends ConsumerStatefulWidget {
  const NotificationOptIn({super.key});
  @override
  ConsumerState<NotificationOptIn> createState() => _NotificationOptInState();
}

class _NotificationOptInState extends ConsumerState<NotificationOptIn> {
  bool busy = false, enabled = false;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enabled
              ? 'Browser reminders enabled'
              : 'A gentle reminder before your visit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Get your booking updates on this device. This is optional.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy || enabled
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    final ok = await ref
                        .read(notificationRepositoryProvider)
                        .enable();
                    if (mounted) {
                      setState(() => enabled = ok);
                      if (!ok)
                        showMessage(
                          context,
                          'You can enable notifications later in your browser settings.',
                        );
                    }
                  } catch (e) {
                    if (mounted) showMessage(context, failureMessage(e));
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(
            busy
                ? 'Enabling…'
                : enabled
                ? 'Enabled'
                : 'Enable reminders',
          ),
        ),
      ],
    ),
  );
}
