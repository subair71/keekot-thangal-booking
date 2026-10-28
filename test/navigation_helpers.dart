import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise the same language controls visitors use in the navigation drawer.
Future<void> selectDrawerLanguage(WidgetTester tester, String language) async {
  await tester.tap(find.byKey(const ValueKey('header-menu')));
  await tester.pumpAndSettle();
  final choice = find.byKey(ValueKey('navigation-language-$language'));
  if (choice.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      choice,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('navigation-links')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('close-navigation')));
  await tester.pumpAndSettle();
}
