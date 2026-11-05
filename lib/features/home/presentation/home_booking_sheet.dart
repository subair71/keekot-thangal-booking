import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/components.dart';
import 'quick_booking_card.dart';

/// Keep the home route and its scroll position beneath the booking controls.
Future<void> showHomeBookingSheet(BuildContext context) async {
  final router = GoRouter.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final next = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.ivory,
    constraints: const BoxConstraints(maxWidth: 640),
    routeSettings: const RouteSettings(name: 'home-booking-sheet'),
    builder: (_) => const HomeBookingSheet(),
  );
  if (navigator.mounted && next != null) router.go(next);
}

class HomeBookingSheet extends ConsumerWidget {
  const HomeBookingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FractionallySizedBox(
    heightFactor: .9,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: AppText(
                        'Book a visit',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('home-booking-close'),
                    tooltip: tr(context, 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('home-booking-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: AsyncPanel(
                  value: ref.watch(configurationProvider),
                  onRetry: () => ref.invalidate(configurationProvider),
                  builder: (config) => QuickBookingCard(
                    config: config,
                    mobileDesign: MediaQuery.sizeOf(context).width < 768,
                    showViewAll: false,
                    onContinue: () => Navigator.of(context).pop(
                      '/book/confirmation',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomeBookingLauncher extends StatelessWidget {
  const HomeBookingLauncher({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: AppColors.cream,
    padding: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Plan your visit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('home-booking-open'),
          onPressed: () => showHomeBookingSheet(context),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const AppText(
            'Reserve a Visit Slot',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        const AppText(
          '100% Free Booking · No fees required at any stage',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );
}
