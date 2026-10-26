import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/errors/app_failure.dart';
import 'package:keekot_thangal/features/admin/domain/admin_repository.dart';
import 'package:keekot_thangal/features/admin/presentation/admin_page.dart';

class GateRepository implements AdminRepository {
  int calls = 0;
  bool? checkIn;
  Completer<Map<String, dynamic>>? pending;
  AppFailure? failure;
  Map<String, dynamic> response = {'valid': true, 'status': 'completed'};
  @override
  Future<Map<String, dynamic>> validatePass(String token, bool checkIn) async {
    calls++;
    this.checkIn = checkIn;
    if (failure != null) throw failure!;
    return pending?.future ?? response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> showGate(WidgetTester tester, GateRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GateValidation())),
      ),
    ),
  );
}

void main() {
  testWidgets('rejects unrelated QR data without contacting server', (
    tester,
  ) async {
    final repository = GateRepository();
    await showGate(tester, repository);
    await tester.enterText(find.byType(TextField), 'https://unrelated.example');
    await tester.tap(find.text('Verify and confirm visit'));
    await tester.pump();
    expect(repository.calls, 0);
    expect(
      find.text('This is not a valid visitor pass QR code.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'confirms once and disables entry while verification is pending',
    (tester) async {
      final repository = GateRepository()
        ..pending = Completer<Map<String, dynamic>>();
      await showGate(tester, repository);
      await tester.enterText(find.byType(TextField), 'a' * 43);
      await tester.tap(find.text('Verify and confirm visit'));
      await tester.pump();
      expect(repository.calls, 1);
      expect(repository.checkIn, true);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      repository.pending!.complete({'valid': true, 'status': 'completed'});
      await tester.pumpAndSettle();
      expect(find.text('Visit confirmed'), findsOneWidget);
      await tester.tap(find.text('Verify and confirm visit'));
      expect(repository.calls, 1);
    },
  );

  testWidgets('already used passes are never presented as successful', (
    tester,
  ) async {
    final repository = GateRepository()
      ..response = {
        'valid': false,
        'reason': 'already_used',
        'status': 'completed',
      };
    await showGate(tester, repository);
    await tester.enterText(find.byType(TextField), 'b' * 43);
    await tester.tap(find.text('Verify and confirm visit'));
    await tester.pumpAndSettle();
    expect(find.text('Visit confirmed'), findsNothing);
    expect(
      find.text('This pass has already been used. Do not admit again.'),
      findsOneWidget,
    );
  });

  testWidgets('assignment permission errors never confirm a visit', (
    tester,
  ) async {
    const message = 'This visit is not assigned to you.';
    final repository = GateRepository()
      ..failure = const AppFailure(message, code: 'permission-denied');
    await showGate(tester, repository);
    await tester.enterText(find.byType(TextField), 'c' * 43);
    await tester.tap(find.text('Verify and confirm visit'));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text(message), findsOneWidget);
    expect(find.text('Visit confirmed'), findsNothing);
    expect(find.text('Valid for entry'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
