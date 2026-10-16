import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  testWidgets(
    'carousel dots select slides and use localized images without visible captions',
    (tester) async {
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
      expect(find.text('Every Thursday after Maghrib.'), findsNothing);
      expect(
        find.image(const AssetImage('assets/brand/programme-dhikr-en.webp')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('carousel-pause')), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1,
      );
      final dot = find.byKey(const ValueKey('carousel-dot-2'));
      await tester.ensureVisible(dot);
      await tester.tap(dot);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        2,
      );
      final selectedDot = tester.widget<IconButton>(dot).icon as Container;
      final otherButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('carousel-dot-0')),
      );
      final otherDot = otherButton.icon as Container;
      expect(
        selectedDot.constraints!.maxWidth,
        greaterThan(otherDot.constraints!.maxWidth),
      );
      await tester.pump(const Duration(seconds: 8));
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        2,
      );
      language.value = 'ml';
      await tester.pump();
      expect(find.text('ആണ്ട് നേർച്ച'), findsNothing);
      expect(
        find.image(
          const AssetImage('assets/brand/programme-annual-small.webp'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'reduced motion prevents autoplay but keyboard can change slides',
    (tester) async {
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
      expect(find.text('Every Thursday after Maghrib.'), findsNothing);
      expect(
        find.image(const AssetImage('assets/brand/programme-dhikr-en.webp')),
        findsOneWidget,
      );
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );
      final carouselSize = tester.getSize(find.byType(ProgrammeCarousel));
      // Keyboard navigation remains available when automatic sliding is off.
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
      expect(
        find.image(const AssetImage('assets/brand/programme-mawlid-en.webp')),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(ProgrammeCarousel)), carouselSize);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
