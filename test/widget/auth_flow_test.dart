import 'package:beautyhub/app.dart';
import 'package:beautyhub/core/di/providers.dart';
import 'package:beautyhub/data/repositories/mock_auth_repository.dart';
import 'package:beautyhub/data/repositories/mock_booking_repository.dart';
import 'package:beautyhub/data/repositories/mock_salon_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      // Widget tests stay hermetic on the in-memory mocks.
      overrides: [
        salonRepositoryProvider.overrideWithValue(MockSalonRepository()),
        bookingRepositoryProvider.overrideWithValue(MockBookingRepository()),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
      child: const BeautyHubApp(),
    ),
  );
  // Splash hands off to home after 3 seconds.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _openProfile(WidgetTester tester) async {
  // Target the tab label: the global router keeps its state between tests,
  // so a profile AppBar title may already exist.
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text('Profile'),
  ));
  await tester.pumpAndSettle();
}

Future<void> _scrollProfileTo(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
      target, find.byType(ListView), const Offset(0, -120));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guest can sign in from the profile tab', (tester) async {
    await _pumpApp(tester);
    await _openProfile(tester);

    // Guest identity card with auth entry points.
    expect(find.text('Guest'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);

    // Empty submit surfaces validation, not a request.
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).first, 'thandi@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Back on profile, now signed in. The sign-out tile lives below the
    // fold, so scroll it into existence before asserting.
    expect(find.text('thandi'), findsOneWidget);
    expect(find.text('thandi@example.com'), findsOneWidget);
    await _scrollProfileTo(tester, find.text('Sign out'));
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('guest can create an account and sign out again',
      (tester) async {
    await _pumpApp(tester);
    await _openProfile(tester);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);

    // Short password is rejected client-side (API requires 8+).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Thandi M');
    await tester.enterText(fields.at(1), 'thandi@example.com');
    await tester.enterText(fields.at(2), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(fields.at(2), 'long-enough-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Thandi M'), findsOneWidget);

    // Sign out returns the profile to the guest state.
    await _scrollProfileTo(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    // Scroll back up — the list is still at the bottom from tapping the
    // sign-out tile, so the identity card isn't built yet.
    await tester.dragUntilVisible(
        find.text('Guest'), find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
