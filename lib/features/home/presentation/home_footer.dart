import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/booking_share_button.dart';
import '../../../core/widgets/components.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key, required this.onVideos});
  final VoidCallback onVideos;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.emerald,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.cream,
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 28 : 44,
          ),
          child: Column(
            children: [
              const Icon(Icons.spa_outlined, color: AppColors.gold, size: 32),
              const SizedBox(height: 16),
              AppText(
                'Your next visit begins with a little planning.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const AppText(
                'Find a suitable time and prepare for a peaceful ziyarat at Keekkott Sayyid Attakoya Thangal Maqam.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/book'),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const AppText('Plan my visit'),
                  ),
                  const BookingShareButton(),
                ],
              ),
              const SizedBox(height: 14),
              const AppText(
                'Share the invitation with family and friends.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final brand = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Emblem(size: 58),
                ),
                const SizedBox(height: 18),
                AppText(
                  'KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium!.copyWith(color: AppColors.ivory),
                ),
                const SizedBox(height: 8),
                const AppText(
                  'Ziyarat & visitor booking · Chavakkad, Kerala',
                  style: TextStyle(color: Color(0xFFD9E6DF)),
                ),
              ],
            );
            final links = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterHeading('Plan your ziyarat'),
                const SizedBox(height: 12),
                _link(
                  context,
                  'Book Visit',
                  Icons.calendar_month_outlined,
                  () => context.go('/book'),
                ),
                _link(
                  context,
                  'My bookings',
                  Icons.confirmation_number_outlined,
                  () => context.go('/my-bookings'),
                ),
                _link(
                  context,
                  'Visitor information',
                  Icons.info_outline,
                  () => context.go('/information'),
                ),
                _link(context, 'Videos', Icons.play_circle_outline, onVideos),
                Link(
                  uri: Uri.parse(
                    'https://www.keekkottbungalow.com/visitor-guide.html',
                  ),
                  builder: (context, followLink) => _link(
                    context,
                    'Public visitor guide',
                    Icons.article_outlined,
                    () => followLink?.call(),
                  ),
                ),
                _link(
                  context,
                  'Contact us',
                  Icons.mail_outline,
                  () => context.go('/contact'),
                ),
              ],
            );
            final guidance = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterHeading('Before your visit'),
                const SizedBox(height: 16),
                const AppText(
                  'Keep your booking details ready and review the visitor guidance before travelling.',
                  style: TextStyle(color: Color(0xFFD9E6DF), height: 1.7),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .15),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: AppColors.mintStrong,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          'All visit times are in India Standard Time.',
                          style: TextStyle(
                            color: AppColors.ivory,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            return Padding(
              padding: EdgeInsets.all(wide ? 36 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: brand),
                        const SizedBox(width: 36),
                        Expanded(flex: 3, child: links),
                        const SizedBox(width: 36),
                        Expanded(flex: 3, child: guidance),
                      ],
                    )
                  else ...[
                    brand,
                    const SizedBox(height: 20),
                    links,
                    const SizedBox(height: 18),
                    guidance,
                  ],
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: .18)),
                  const SizedBox(height: 14),
                  const AppText(
                    'A considerate visit. A peaceful atmosphere.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mintStrong, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _link(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: AppText(label),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.ivory,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
    ),
  );
}

class _FooterHeading extends StatelessWidget {
  const _FooterHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => AppText(
    text,
    style: const TextStyle(
      color: AppColors.mintStrong,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );
}
