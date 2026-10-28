import 'package:flutter/material.dart';

import 'malayalam.dart';
import 'sanctuary_malayalam.dart';
import 'staff_malayalam.dart';
import 'language_storage.dart';

class LanguageRoot extends StatefulWidget {
  const LanguageRoot({super.key, required this.child});
  final Widget child;
  @override
  State<LanguageRoot> createState() => _LanguageRootState();
}

class _LanguageRootState extends State<LanguageRoot> {
  late final language = ValueNotifier<String>(
    readLanguage() == 'ml' ? 'ml' : 'en',
  );
  @override
  void dispose() {
    language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppLanguage(notifier: language, child: widget.child);
}

class AppLanguage extends InheritedNotifier<ValueNotifier<String>> {
  const AppLanguage({super.key, required super.notifier, required super.child});
  static String of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppLanguage>()
          ?.notifier
          ?.value ??
      'en';
  static void select(BuildContext context, String value) {
    context.getInheritedWidgetOfExactType<AppLanguage>()?.notifier?.value =
        value;
    saveLanguage(value);
  }
}

String tr(BuildContext context, String text) =>
    AppLanguage.of(context) == 'ml' ? translateMalayalam(text) : text;

String translateMalayalam(String text) {
  final direct =
      staffMalayalam[text] ?? sanctuaryMalayalam[text] ?? malayalam[text];
  if (direct != null) return direct;
  final patterns = <(RegExp, String Function(RegExpMatch))>[
    (
      RegExp(r'^1\. Select dates \((\d+)\)$'),
      (m) => '1. തീയതികൾ തിരഞ്ഞെടുക്കുക (${m[1]})',
    ),
    (
      RegExp(r'^(\d+) entire days selected$'),
      (m) => '${m[1]} ദിവസങ്ങൾ മുഴുവൻ തിരഞ്ഞെടുത്തു',
    ),
    (
      RegExp(r'^(\d+) dates · (\d+) slots per date$'),
      (m) => '${m[1]} തീയതികൾ · ഓരോ ദിവസവും ${m[2]} സമയങ്ങൾ',
    ),
    (RegExp(r'^Start: (.+)$'), (m) => 'ആരംഭം: ${m[1]}'),
    (RegExp(r'^End: (.+)$'), (m) => 'അവസാനം: ${m[1]}'),
    (
      RegExp(r'^Current hours: (.+)$'),
      (m) => 'നിലവിലെ സമയം: ${m[1]!.replaceAll('(default)', '(പതിവ്)')}',
    ),
    (
      RegExp(r'^Hours saved for (.+)\.$'),
      (m) => '${translateMalayalam(m[1]!)}: സമയം സംരക്ഷിച്ചു.',
    ),
    (
      RegExp(r'^Default hours restored for (.+)\.$'),
      (m) => '${translateMalayalam(m[1]!)}: പതിവ് സമയം പുനഃസ്ഥാപിച്ചു.',
    ),
    (
      RegExp(r'^Report prepared for (.+) \(India time\)\.$'),
      (m) => '${m[1]}-ലെ റിപ്പോർട്ട് തയ്യാറായി (ഇന്ത്യൻ സമയം).',
    ),
    (
      RegExp(r'^Your assigned khadim is (.+)\.$'),
      (m) => 'നിങ്ങൾക്ക് നിയോഗിച്ച ഖാദിം: ${m[1]}.',
    ),
    (
      RegExp(
        r'^(Your Keekkott Sayyid Attakoya Thangal Maqam visit|The visit you booked for a visitor) (begins|is confirmed) at (.+) on (.+)\.$',
      ),
      (m) =>
          '${m[4]}-ന് ${m[3]}-ലെ ${m[1]!.startsWith('The') ? 'നിങ്ങൾ സന്ദർശകനായി ബുക്ക് ചെയ്ത സന്ദർശനം' : 'നിങ്ങളുടെ മഖാം സന്ദർശനം'} ${m[2] == 'begins' ? 'ആരംഭിക്കും' : 'സ്ഥിരീകരിച്ചു'}. ',
    ),
    (RegExp(r'^Token number: (.+)$'), (m) => 'ടോക്കൺ നമ്പർ: ${m[1]}'),
    (
      RegExp(
        r'^Delete (.+) permanently\? Reassign active visits first\. This cannot be undone\.$',
      ),
      (m) =>
          '${m[1]} എന്ന അക്കൗണ്ട് സ്ഥിരമായി നീക്കണോ? സജീവ സന്ദർശനങ്ങൾ ആദ്യം മറ്റൊരാൾക്ക് നിയോഗിക്കുക. ഇത് തിരിച്ചെടുക്കാനാവില്ല.',
    ),
    (
      RegExp(
        r'^End time must be after start time and hours must contain complete (\d+)-minute slots\.$',
      ),
      (m) =>
          'അവസാന സമയം ആരംഭത്തിന് ശേഷമായിരിക്കണം. ${m[1]} മിനിറ്റിന്റെ പൂർണ്ണ സമയങ്ങൾ ഉൾപ്പെടണം.',
    ),
    (
      RegExp(
        r'^Choose an end time after the start time with complete (\d+)-minute slots\.$',
      ),
      (m) =>
          'ആരംഭത്തിന് ശേഷമുള്ള അവസാന സമയം തിരഞ്ഞെടുക്കുക. ${m[1]} മിനിറ്റിന്റെ പൂർണ്ണ സമയങ്ങൾ വേണം.',
    ),
    (
      RegExp(
        r'^Proposed hours: (.+) · (\d+) complete slots, (\d+) minutes each\. Availability still depends on closures and capacity\.$',
      ),
      (m) =>
          'പുതിയ സമയം: ${m[1]} · ${m[2]} പൂർണ്ണ സമയങ്ങൾ, ഓരോന്നും ${m[3]} മിനിറ്റ്. ലഭ്യത ഒഴിവുദിവസങ്ങളെയും ശേഷിയെയും ആശ്രയിക്കുന്നു.',
    ),
    (
      RegExp(r'^(\d+) of (\d+) schedule changes saved\.$'),
      (m) => '${m[2]} സമയമാറ്റങ്ങളിൽ ${m[1]} സംരക്ഷിച്ചു.',
    ),
    (RegExp(r'^(\d+)-Min Slots$'), (m) => '${m[1]} മിനിറ്റ് സമയം'),
    (
      RegExp(r'^Select Date & (\d+)-Minute Slot$'),
      (m) => 'തീയതിയും ${m[1]} മിനിറ്റ് സമയവും തിരഞ്ഞെടുക്കുക',
    ),
    (
      RegExp(r'^Why are visits scheduled in (\d+)-minute slots\?$'),
      (m) => 'സന്ദർശനം ${m[1]} മിനിറ്റായി നിശ്ചയിക്കുന്നത് എന്തുകൊണ്ട്?',
    ),
    (
      RegExp(r'^(\d+) available time slots$'),
      (m) => '${m[1]} സമയങ്ങൾ ലഭ്യമാണ്',
    ),
    (
      RegExp(r'^(\d+) minutes per slot$'),
      (m) => 'ഓരോ സ്ലോട്ടിനും ${m[1]} മിനിറ്റ്',
    ),
    (RegExp(r'^(\d+) places left$'), (m) => '${m[1]} സ്ഥലങ്ങൾ ബാക്കി'),
    (RegExp(r'^(\d+) visitors?$'), (m) => '${m[1]} സന്ദർശകർ'),
    (
      RegExp(r'^Up to (\d+) visitors per booking\.$'),
      (m) => 'ഒരു ബുക്കിംഗിൽ പരമാവധി ${m[1]} സന്ദർശകർ.',
    ),
    (
      RegExp(r'^Please arrive (\d+) minutes early and keep your pass ready\.$'),
      (m) => '${m[1]} മിനിറ്റ് നേരത്തെ എത്തി പാസ് തയ്യാറാക്കി വയ്ക്കുക.',
    ),
    (
      RegExp(r'^Please arrive (\d+) minutes before your visit\.$'),
      (m) => 'സന്ദർശനത്തിന് ${m[1]} മിനിറ്റ് മുമ്പ് എത്തുക.',
    ),
    (
      RegExp(r'^Request a new code in (\d+)s$'),
      (m) => '${m[1]} സെക്കൻഡിന് ശേഷം പുതിയ കോഡ് ആവശ്യപ്പെടാം',
    ),
    (RegExp(r'^Held (\d+:\d+)$'), (m) => 'മാറ്റിവച്ച സമയം ${m[1]}'),
    (
      RegExp(r'^(\d+) minutes · India time$'),
      (m) => '${m[1]} മിനിറ്റ് · ഇന്ത്യൻ സമയം',
    ),
    (RegExp(r'^Booking reference: (.+)$'), (m) => 'ബുക്കിംഗ് റഫറൻസ്: ${m[1]}'),
  ];
  for (final (pattern, format) in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) return format(match);
  }
  // Only recognize date/time display values, never change stored date keys.
  const weekdays = {
    'Mon': 'തിങ്കൾ',
    'Tue': 'ചൊവ്വ',
    'Wed': 'ബുധൻ',
    'Thu': 'വ്യാഴം',
    'Fri': 'വെള്ളി',
    'Sat': 'ശനി',
    'Sun': 'ഞായർ',
  };
  const months = {
    'Jan': 'ജനുവരി',
    'Feb': 'ഫെബ്രുവരി',
    'Mar': 'മാർച്ച്',
    'Apr': 'ഏപ്രിൽ',
    'May': 'മേയ്',
    'Jun': 'ജൂൺ',
    'Jul': 'ജൂലൈ',
    'Aug': 'ഓഗസ്റ്റ്',
    'Sep': 'സെപ്റ്റംബർ',
    'Oct': 'ഒക്ടോബർ',
    'Nov': 'നവംബർ',
    'Dec': 'ഡിസംബർ',
  };
  if (RegExp(
    r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d+ [A-Z][a-z]{2} \d{4}',
  ).hasMatch(text)) {
    return text
        .replaceAllMapped(
          RegExp(r'\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b'),
          (m) => weekdays[m[0]]!,
        )
        .replaceAllMapped(
          RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b'),
          (m) => months[m[0]]!,
        );
  }
  if (text.contains('\n')) {
    return text.split('\n').map(translateMalayalam).join('\n');
  }
  if (RegExp(r'^\d{1,2}:\d{2} (AM|PM)').hasMatch(text)) {
    return text.replaceAllMapped(
      RegExp(r'(\d+) visitors?\b'),
      (m) => '${m[1]} സന്ദർശകർ',
    );
  }
  return text;
}

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
  }) : span = null;
  const AppText.rich(
    this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
  }) : data = null;
  final String? data, semanticsLabel;
  final InlineSpan? span;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  TextStyle? localizedStyle(BuildContext context, TextStyle? value) =>
      AppLanguage.of(context) == 'ml'
      ? (value ?? const TextStyle()).copyWith(
          fontFamily: 'Noto Sans Malayalam',
          height: (value?.height ?? 1.5) < 1.6 ? 1.6 : value!.height,
          letterSpacing: 0,
        )
      : (value ?? const TextStyle()).copyWith(
          fontFamilyFallback: const ['Noto Sans Malayalam'],
        );
  InlineSpan translatedSpan(BuildContext context, InlineSpan value) {
    if (value is! TextSpan) return value;
    return TextSpan(
      text: value.text == null ? null : tr(context, value.text!),
      style: localizedStyle(context, value.style),
      recognizer: value.recognizer,
      children: value.children?.map((v) => translatedSpan(context, v)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (span != null) {
      return Text.rich(
        translatedSpan(context, span!),
        style: localizedStyle(context, style),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        semanticsLabel: semanticsLabel == null
            ? null
            : tr(context, semanticsLabel!),
        textDirection: textDirection,
      );
    }
    return Text(
      tr(context, data!),
      style: localizedStyle(context, style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel == null
          ? null
          : tr(context, semanticsLabel!),
      textDirection: textDirection,
    );
  }
}

/// Compact header control; retains the existing persisted language setting.
class HeaderLanguageToggle extends StatelessWidget {
  const HeaderLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final ml = AppLanguage.of(context) == 'ml';
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: ml ? 'Switch to English' : 'മലയാളത്തിലേക്ക് മാറ്റുക',
      toggled: ml,
      child: TextButton(
        key: const ValueKey('language-toggle'),
        onPressed: () => AppLanguage.select(context, ml ? 'en' : 'ml'),
        style: TextButton.styleFrom(
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: colors.primary.withValues(alpha: 0.06),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: ml ? FontWeight.w400 : FontWeight.w700,
                color: ml ? colors.onSurfaceVariant : colors.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text('|', style: TextStyle(color: colors.outline)),
            ),
            Text(
              'മലയാളം',
              style: TextStyle(
                fontFamily: 'Noto Sans Malayalam',
                fontSize: 11,
                fontWeight: ml ? FontWeight.w700 : FontWeight.w400,
                color: ml ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
