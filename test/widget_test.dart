import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_turf/main.dart';
import 'package:sports_turf/core/models/app_user.dart';
import 'package:sports_turf/core/providers/auth_providers.dart';
import 'package:sports_turf/features/tournament/providers/tournament_providers.dart';

void main() {
  testWidgets('App displays LoginScreen when user is not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          tournamentsListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login screen elements are shown
    expect(find.text('Sports Turf Tournaments'), findsOneWidget);
    expect(find.text('Sign In with Google'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Continue as Guest (Offline Mode)'), findsNothing);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('App displays HomeScreen when user is logged in', (WidgetTester tester) async {
    final loggedInUser = AppUser(
      id: 'test_user_1',
      email: 'test@turf.com',
      displayName: 'Alex Morgan',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(loggedInUser)),
          tournamentsListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify home screen elements are shown
    expect(find.text('Sports Turf'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Coin Toss'), findsOneWidget);
    expect(find.text('Tennis Score'), findsOneWidget);
    expect(find.text('Badminton'), findsOneWidget);
  });
}
