import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  for (final viewportWidth in [360.0, 1280.0]) {
    testWidgets('compact banner strip at width $viewportWidth', (tester) async {
      await tester.binding.setSurfaceSize(Size(viewportWidth, 800));
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

      final strip = find.byKey(const ValueKey('programme-thumbnail-strip'));
      final viewport = tester.getRect(strip);
      final images = find.byType(Image);
      expect(images, findsNWidgets(3));
      final first = tester.getRect(images.at(0));
      final second = tester.getRect(images.at(1));
      final third = tester.getRect(images.at(2));

      expect(first.left, closeTo(viewport.left, 0.1));
      expect(second.right, lessThan(viewport.right));
      expect(third.left, lessThan(viewport.right));
      expect(third.right, greaterThan(viewport.right));
      expect(first.width / first.height, closeTo(16 / 9, 0.01));
      expect((viewport.right - third.left) / third.width, closeTo(0.3, 0.01));
      final image = tester.widget<Image>(images.first);
      expect(
        (image.image as AssetImage).assetName,
        'assets/brand/programme-dhikr.webp',
      );
      expect(image.semanticLabel, contains('Thursday'));

      language.value = 'ml';
      await tester.pumpAndSettle();
      expect(
        tester.widget<Image>(images.first).semanticLabel,
        contains('വ്യാഴാഴ്ച'),
      );

      await tester.drag(strip, const Offset(-600, 0));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.byType(Image).last);
      expect(last.right, lessThanOrEqualTo(viewport.right + 0.1));
      expect(tester.takeException(), isNull);
    });
  }
}
