import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  testWidgets('carousel pauses, resumes and exposes bilingual live text', (
    tester,
  ) async {
    final language = ValueNotifier('en');
    addTearDown(language.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AppLanguage(
          notifier: language,
          child: const Scaffold(
            body: SingleChildScrollView(child: ProgrammeCarousel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Every Thursday after Maghrib.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('carousel-pause')));
    await tester.tap(find.byKey(const ValueKey('carousel-pause')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Every Thursday after Maghrib.'), findsOneWidget);
    expect(find.text('Resume slideshow'), findsOneWidget);
    language.value = 'ml';
    await tester.pump();
    expect(find.text('എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('carousel-pause')));
    await tester.tap(find.byKey(const ValueKey('carousel-pause')));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('മൗലിദ് സദസ്സ്'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion prevents autoplay but keyboard can change slides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(child: ProgrammeCarousel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Every Thursday after Maghrib.'), findsOneWidget);
    expect(find.text('Automatic sliding is off'), findsOneWidget);
    final captionSize = tester.getSize(find.byType(IndexedStack));
    // Focus the carousel itself: its pause control is disabled by reduced motion.
    final carouselFocus = find
        .descendant(
          of: find.byType(ProgrammeCarousel),
          matching: find.byType(Focus),
        )
        .first;
    Focus.of(
      tester.element(
        find
            .descendant(of: carouselFocus, matching: find.byType(MouseRegion))
            .first,
      ),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Mawlid gathering'), findsOneWidget);
    expect(tester.getSize(find.byType(IndexedStack)), captionSize);
    await tester.pumpWidget(const SizedBox());
  });
}
