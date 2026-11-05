import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/features/home/presentation/home_notice_banner.dart';
import 'package:keekot_thangal/features/home/presentation/notice_reason_ticker.dart';
import 'package:keekot_thangal/features/notifications/domain/home_notice.dart';

const reason = 'Visits postponed due to maintenance.';

Widget tickerApp({bool reduceMotion = false, String text = reason}) => MaterialApp(
  theme: buildTheme(),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: SizedBox(
          width: 300,
          child: NoticeReasonTicker(
            text: text,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ),
    ),
  ),
);

double position(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('notice-reason-motion')))
    .transform
    .getTranslation()
    .x;

void main() {
  testWidgets('reason moves left, loops, and stays a single clipped line', (
    tester,
  ) async {
    await tester.pumpWidget(tickerApp());
    await tester.pump();
    final initial = position(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(position(tester), lessThan(initial));
    final text = tester.widget<Text>(find.text(reason));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    await tester.pump(const Duration(minutes: 2));
    expect(position(tester), lessThanOrEqualTo(300));
    expect(position(tester), greaterThan(-tester.getSize(find.text(reason)).width - 25));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hover pauses the reason and exit resumes it', (tester) async {
    await tester.pumpWidget(tickerApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(NoticeReasonTicker)));
    await tester.pump();
    final paused = position(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(position(tester), paused);
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(position(tester), lessThan(paused));
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion stops scrolling and keeps the full reason readable', (
    tester,
  ) async {
    final longReason = List.filled(10, reason).join(' ');
    await tester.pumpWidget(tickerApp(text: longReason));
    await tester.pump();
    await tester.pumpWidget(tickerApp(text: longReason, reduceMotion: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice-reason-motion')), findsNothing);
    expect(find.text(longReason), findsOneWidget);
    expect(tester.widget<Text>(find.text(longReason)).maxLines, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('long notices use a compact card on a phone', (tester) async {
    final notice = HomeNotice(
      visitDate: '2026-11-05',
      reason: List.filled(8, reason).join(' '),
      active: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 343, child: HomeNoticeCard(notice: notice)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSize(find.byType(HomeNoticeCard)).height, lessThan(100));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
