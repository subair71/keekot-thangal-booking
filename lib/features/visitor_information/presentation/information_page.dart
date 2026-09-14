import 'package:flutter/material.dart';
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
          'A peaceful visit starts here',
          eyebrow: 'Visitor information',
          subtitle: 'A few things to know before you arrive.',
        ),
        TwoColumn(main: GuidelinesCard(), aside: LocationCard()),
        SizedBox(height: 28),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your information',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your name and verified mobile number support your booking. Your digital pass uses a private token. Keep it safe and only show it to entry staff. You can cancel an eligible booking from My Bookings.',
              ),
              SizedBox(height: 12),
              Text(
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
          Text(
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
          Text(
            'Keekot Thangal Maqam',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Chavakkad, Kerala, India'),
          const SizedBox(height: 24),
          if (config?.locationUrl.isNotEmpty == true)
            OutlinedButton.icon(
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse(config!.locationUrl),
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
              label: const Text('Get directions'),
            )
          else
            const Text('Detailed directions will appear here when available.'),
          if (config?.contactPhone.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: config.contactPhone)),
              icon: const Icon(Icons.call_outlined),
              label: Text(config!.contactPhone),
            ),
          ],
        ],
      ),
    );
  }
}
