import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});
  @override
  Widget build(BuildContext context) => const PageContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Your guide to Keekkott Sayyid Attakoya Thangal Maqam',
          eyebrow: 'Visitor information',
          subtitle:
              'Prepare for ziyarat with practical guidance for your journey, arrival and time at the Maqam.',
        ),
        SurfaceCard(
          color: AppColors.cream,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Welcome to Keekkott Sayyid Attakoya Thangal Maqam',
                style: TextStyle(
                  fontFamily: 'Newsreader',
                  fontSize: 28,
                  color: AppColors.emerald,
                ),
              ),
              SizedBox(height: 14),
              AppText(
                'Located in Chavakkad, Kerala, Keekkott Sayyid Attakoya Thangal Maqam is a place to approach with respect, remembrance and quiet reflection. Plan your ziyarat around your confirmed booking and follow the guidance of the Maqam staff during your visit.',
              ),
              SizedBox(height: 16),
              AppText(
                'Before travelling, check your reservation, allow enough time for your journey and keep your digital pass accessible. If you are accompanying children or older family members, plan a comfortable journey together.',
              ),
            ],
          ),
        ),
        SizedBox(height: 28),
        TwoColumn(main: GuidelinesCard(), aside: LocationCard()),
        SizedBox(height: 28),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Your information',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald,
                ),
              ),
              SizedBox(height: 12),
              AppText(
                'Your name and verified mobile number support your booking. Your digital pass uses a private token. Keep it safe and only show it to entry staff. You can cancel an eligible booking from My Bookings.',
              ),
              SizedBox(height: 12),
              AppText(
                'Phone verification is provided by Google Firebase. Phone numbers are sent to Google for authentication and abuse prevention. Browser reminders are optional.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class GuidelinesCard extends ConsumerWidget {
  const GuidelinesCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).asData?.value;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Visiting etiquette',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const InfoLine(
            Icons.spa_outlined,
            'Dress respectfully',
            'Choose modest attire for your visit.',
          ),
          const SizedBox(height: 24),
          InfoLine(
            Icons.schedule,
            'Allow time to arrive',
            config == null
                ? 'Check your confirmed visit time before travelling.'
                : 'Please arrive ${config.arrivalMinutes} minutes before your visit.',
          ),
          const SizedBox(height: 24),
          const InfoLine(
            Icons.volume_off_outlined,
            'Keep the atmosphere peaceful',
            'Silence your mobile phone and be considerate of others.',
          ),
          const SizedBox(height: 24),
          const InfoLine(
            Icons.qr_code_2,
            'Bring your digital pass',
            'Show your QR pass to entry staff. One pass covers the visitors on your booking.',
          ),
        ],
      ),
    );
  }
}

class LocationCard extends ConsumerWidget {
  const LocationCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).asData?.value;
    return SurfaceCard(
      color: AppColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 40,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 20),
          AppText(
            'Keekkott Sayyid Attakoya Thangal Maqam',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const AppText('Chavakkad, Kerala, India'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final opened = await launchUrl(
                Uri.parse('https://maps.app.goo.gl/EeBuXUcd7LHgeig17?g_st=ic'),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && context.mounted) {
                showMessage(
                  context,
                  'Directions could not be opened. Please try again.',
                );
              }
            },
            icon: const Icon(Icons.directions_outlined),
            label: const AppText('Get directions'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/contact'),
            icon: const Icon(Icons.mail_outline),
            label: const AppText('Contact us'),
          ),
          if (config?.contactPhone.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: config.contactPhone)),
              icon: const Icon(Icons.call_outlined),
              label: AppText(config!.contactPhone),
            ),
          ],
        ],
      ),
    );
  }
}
