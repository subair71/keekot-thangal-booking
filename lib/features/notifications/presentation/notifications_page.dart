import 'package:keekot_thangal/core/localization/app_language.dart';
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
                              AppText(
                                n.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              AppText(n.body),
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
                                  if (context.mounted) {
                                    context.go('/booking/${n.bookingId}');
                                  }
                                },
                                child: const AppText('View booking'),
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
        AppText(
          enabled
              ? 'Booking notifications enabled'
              : 'Get your booking confirmation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const AppText(
          'Enable notifications before confirming your booking to receive an alert on this device. Updates also appear in Notifications.',
        ),
        const SizedBox(height: 8),
        const AppText(
          'On iPhone, add this app to your Home Screen and open it there to enable notifications.',
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
                      if (!ok && context.mounted) {
                        showMessage(
                          context,
                          'You can enable notifications later in your browser settings.',
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showMessage(context, failureMessage(e));
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          icon: const Icon(Icons.notifications_active_outlined),
          label: AppText(
            busy
                ? 'Enabling…'
                : enabled
                ? 'Enabled'
                : 'Enable notifications',
          ),
        ),
      ],
    ),
  );
}
