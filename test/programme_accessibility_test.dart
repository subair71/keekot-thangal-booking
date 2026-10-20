import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/home/presentation/programme_carousel.dart';

void main() {
  testWidgets('original first banner is displayed in current 16:9 style', (tester) async {
    final language = ValueNotifier('en');
    addTearDown(language.dispose);
    await tester.pumpWidget(MaterialApp(
      home: AppLanguage(
        notifier: language,
        child: const Scaffold(body: ProgrammeCarousel()),
      ),
    ));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image).single);
    expect((image.image as AssetImage).assetName, 'assets/brand/programme-dhikr.webp');
    expect(image.fit, BoxFit.cover);
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio, 16 / 9);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(image.semanticLabel, contains('Thursday'));
    language.value = 'ml';
    await tester.pumpAndSettle();
    expect(tester.widget<Image>(find.byType(Image)).semanticLabel, contains('വ്യാഴാഴ്ച'));
    expect(tester.takeException(), isNull);
  });
}
