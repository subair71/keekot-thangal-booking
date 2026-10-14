import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

import 'fixtures.dart';

class CountingBookings extends FakeBookings {
  int calls = 0;
  Completer<Availability>? pending;

  @override
  Future<Availability> availability(String day) {
    calls++;
    return pending?.future ?? super.availability(day);
  }
}

Widget availabilityWatchers(CountingBookings repository) => ProviderScope(
  overrides: [bookingRepositoryProvider.overrideWithValue(repository)],
  child: Column(
    children: List.generate(
      2,
      (_) => Consumer(
        builder: (context, ref, _) {
          ref.watch(availabilityProvider('2030-01-10'));
          return const SizedBox();
        },
      ),
    ),
  ),
);

void main() {
  testWidgets('shares polling, pauses in background and refreshes on return', (
    tester,
  ) async {
    final repository = CountingBookings();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(availabilityWatchers(repository));
    await tester.pump();
    expect(repository.calls, 1);
    await tester.pump(const Duration(seconds: 20));
    expect(repository.calls, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(minutes: 2));
    expect(repository.calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.calls, 3);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));
    expect(repository.calls, 3);
  });

  testWidgets('does not overlap slow requests or publish after disposal', (
    tester,
  ) async {
    final repository = CountingBookings()..pending = Completer<Availability>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(availabilityWatchers(repository));
    await tester.pump(const Duration(seconds: 40));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.calls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    repository.pending!.complete(Availability(const [], 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
