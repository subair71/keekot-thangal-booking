import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/features/home/presentation/media/sanctuary_video_archive.dart';
import 'package:keekot_thangal/features/home/presentation/media/video_catalog.dart';

void main() {
  testWidgets(
    'long video selection changes player and its direct YouTube link',
    (tester) async {
      String? opened;
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          opened = (call.arguments as Map)['url'] as String;
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SanctuaryVideoArchive(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final video in maqamVideos) {
        expect(
          find.byKey(ValueKey('long-video-${video.id}')),
          video.isShort ? findsNothing : findsOneWidget,
        );
      }
      final target = maqamVideos.where((v) => !v.isShort).elementAt(2);
      final card = find.byKey(ValueKey('long-video-${target.id}'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('youtube-player-${target.id}')),
        findsOneWidget,
      );
      final watch = find.byKey(const ValueKey('watch-featured-youtube'));
      await tester.ensureVisible(watch);
      await tester.tap(watch);
      await tester.pumpAndSettle();
      expect(opened, 'https://www.youtube.com/watch?v=${target.id}');
      expect(find.text('Coming soon'), findsNothing);
      expect(find.textContaining('05:40'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed external video launch gives useful feedback', (
    tester,
  ) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(child: SanctuaryVideoArchive()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final watch = find.byKey(const ValueKey('watch-featured-youtube'));
    await tester.ensureVisible(watch);
    await tester.tap(watch);
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to open YouTube. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
