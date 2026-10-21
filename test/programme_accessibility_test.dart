import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  for (final viewportWidth in [360.0, 1280.0, 1920.0]) {
    testWidgets('banner proportions at width $viewportWidth', (tester) async {
      tester.view.physicalSize = Size(viewportWidth, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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

      final strip = find.byKey(const ValueKey('programme-thumbnail-strip'));
      final viewport = tester.getRect(strip);
      final images = find.byType(Image);
      expect(images, findsAtLeastNWidgets(2));
      final first = tester.getRect(images.at(0));
      final second = tester.getRect(images.at(1));

      expect(first.left, closeTo(viewport.left, 0.1));
      final expectedWidth = viewportWidth < 540 ? viewportWidth * 2 / 3 : 360.0;
      expect(first.width, closeTo(expectedWidth, 0.1));
      expect(first.height, lessThanOrEqualTo(202.5));
      expect(second.left, lessThan(viewport.right));
      if (viewportWidth < 540) {
        expect(second.right, greaterThan(viewport.right));
      } else {
        expect(second.right, lessThan(viewport.right));
        final third = tester.getRect(images.at(2));
        expect(third.left, lessThan(viewport.right));
        expect(third.right, greaterThan(viewport.right));
      }
      expect(find.byType(TextButton), findsNothing);
      expect(first.width / first.height, closeTo(16 / 9, 0.01));
      final image = tester.widget<Image>(images.first);
      expect(
        (image.image as AssetImage).assetName,
        'assets/brand/programme-dhikr.webp',
      );
      expect(image.semanticLabel, contains('Thursday'));
      expect(image.fit, BoxFit.contain);

      language.value = 'ml';
      await tester.pumpAndSettle();
      expect(
        tester.widget<Image>(images.first).semanticLabel,
        contains('വ്യാഴാഴ്ച'),
      );

      await tester.drag(strip, Offset(-viewportWidth * 2, 0));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.byType(Image).last);
      expect(last.right, lessThanOrEqualTo(viewport.right + 0.1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('auto scroll loops and respects reduced motion', (tester) async {
    final language = ValueNotifier('en');
    addTearDown(language.dispose);
    Widget app({bool reducedMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reducedMotion,
        ),
        child: AppLanguage(
          notifier: language,
          child: const Scaffold(body: ProgrammeCarousel()),
        ),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('programme-thumbnail-strip')),
    );
    final controller = list.controller!;
    expect(controller.offset, 0);
    expect(find.byType(TextButton), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);

    await tester.pumpWidget(app(reducedMotion: true));
    await tester.pumpAndSettle();
    final reducedOffset = controller.offset;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(controller.offset, reducedOffset);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
