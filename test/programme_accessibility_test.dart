import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  testWidgets('compact thumbnails show bilingual programme details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final language = ValueNotifier('en');
    addTearDown(language.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AppLanguage(
          notifier: language,
          child: const Scaffold(body: ProgrammeCarousel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('programme-thumbnail-0'));
    final second = find.byKey(const ValueKey('programme-thumbnail-1'));
    expect(tester.getRect(second).right, lessThan(390));
    expect(tester.getSize(first).width, lessThan(180));
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio,
      16 / 9,
    );
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining('On the 10th of every Hijri month'),
      findsWidgets,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    language.value = 'ml';
    await tester.pumpAndSettle();
    expect(find.text('ദിക്ർ ഹൽഖ'), findsOneWidget);
    expect(find.text('എല്ലാ വ്യാഴാഴ്ചയും മഗ്‌രിബിന് ശേഷം'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion stops autoplay but keyboard can scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 844), disableAnimations: true),
          child: Scaffold(body: ProgrammeCarousel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView));
    await tester.pump(const Duration(seconds: 12));
    expect(list.controller!.offset, 0);
    final first = find.byKey(const ValueKey('programme-thumbnail-0'));
    Focus.of(tester.element(first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(list.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('desktop shows all three programmes without scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProgrammeCarousel())),
    );
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.position.maxScrollExtent, 0);
    expect(find.byKey(const ValueKey('programme-thumbnail-2')), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(list.controller!.offset, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
