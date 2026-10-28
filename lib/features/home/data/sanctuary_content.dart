import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Editorial content supplied by the Stitch reference. Keep media IDs empty
/// until the corresponding recording (and its chapter timestamps) is verified.
/// This provider can be overridden by a CMS without changing the mobile UI.
final sanctuaryContentProvider = Provider((ref) => const SanctuaryContent());

class SanctuaryContent {
  const SanctuaryContent({
    this.walkthroughId = '',
    this.guideIds = const ['', '', '', ''],
    this.programmes = const [
      (
        'Weekly Majlis',
        'എല്ലാ ആഴ്ചയും',
        'Thursday',
        'Special Dhikr & Khatm Gathering',
        'Held every Thursday immediately following Maghrib prayer at the historic prayer hall. Open to all pilgrims and families.',
      ),
      (
        'Monthly Mawlid',
        'മാസിക മൗലിദ്',
        'Hijri Dates',
        '24th of Every Hijri Month · Keekkott Attakoya Uppappa',
        '10th of Every Hijri Month · Ahlul Aba Remembrance',
      ),
      (
        'Annual Commemorations',
        'ആണ്ട് നേർച്ച',
        'Annual',
        'Ramadan 8: Keekkott Valiya Uppappa Urs',
        'Safar 24: Keekkott Attakoya Uppappa Urs\nMuharram 10: Ashura & Ahlul Aba Commemoration',
      ),
    ],
    this.assistanceHours =
        'Khadim Desk Assistance available daily 8:30 AM – 8:30 PM',
    this.email = 'keekkottbungalowonline@gmail.com',
  });
  final String walkthroughId, assistanceHours, email;
  final List<String> guideIds;
  final List<(String, String, String, String, String)> programmes;
}
