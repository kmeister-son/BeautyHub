import 'package:beautyhub/app.dart';
import 'package:beautyhub/core/di/providers.dart';
import 'package:beautyhub/data/repositories/mock_booking_repository.dart';
import 'package:beautyhub/data/repositories/mock_salon_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash hands off to home, which loads and shows salons',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Widget tests stay hermetic on the in-memory mocks.
        overrides: [
          salonRepositoryProvider.overrideWithValue(MockSalonRepository()),
          bookingRepositoryProvider.overrideWithValue(MockBookingRepository()),
        ],
        child: const BeautyHubApp(),
      ),
    );

    // Branded splash is shown first.
    expect(find.text('BeautyHub'), findsOneWidget);

    // After 3 seconds the splash navigates to home.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Initial loading state while the mock repository "fetches".
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Find your next look'), findsOneWidget);
    expect(find.text('Featured'), findsWidgets);
    expect(find.text('Velvet & Vine Studio'), findsWidgets);
  });
}
