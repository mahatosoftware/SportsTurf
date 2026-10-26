import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/badminton/models/badminton_match_state.dart';
import 'package:sports_turf/features/badminton/ui/badminton_court_card.dart';
import 'package:sports_turf/features/table_tennis/models/table_tennis_match_state.dart';
import 'package:sports_turf/features/table_tennis/ui/table_tennis_court_card.dart';
import 'package:sports_turf/features/tennis/models/tennis_match_state.dart';
import 'package:sports_turf/features/tennis/ui/tennis_court_card.dart';
import 'package:sports_turf/features/volleyball/ui/volleyball_score_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Court Area Full Surface Tapping Tests', () {
    testWidgets('Badminton: Tapping anywhere inside top or bottom court increments points', (tester) async {
      int scoreACount = 0;
      int scoreBCount = 0;

      final state = BadmintonMatchState.initial(
        playerA1Name: 'Player A',
        playerB1Name: 'Player B',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 600,
                child: BadmintonCourtCard(
                  matchState: state,
                  onScoreA: () => scoreACount++,
                  onScoreB: () => scoreBCount++,
                  onUndo: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(BadmintonCourtCard);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);

      // Tap near top-left edge (inside top court half, far from center score label)
      final topLeftTap = Offset(cardRect.left + 30, cardRect.top + 40);
      await tester.tapAt(topLeftTap);
      await tester.pump();
      expect(scoreACount, 1, reason: 'Tapping near top-left corner should score for Player A');

      // Tap near top-right edge (inside top court half)
      final topRightTap = Offset(cardRect.right - 30, cardRect.top + 50);
      await tester.tapAt(topRightTap);
      await tester.pump();
      expect(scoreACount, 2, reason: 'Tapping near top-right corner should score for Player A');

      // Tap near bottom-left edge (inside bottom court half)
      final bottomLeftTap = Offset(cardRect.left + 30, cardRect.bottom - 40);
      await tester.tapAt(bottomLeftTap);
      await tester.pump();
      expect(scoreBCount, 1, reason: 'Tapping near bottom-left corner should score for Player B');

      // Tap near bottom-right edge (inside bottom court half)
      final bottomRightTap = Offset(cardRect.right - 30, cardRect.bottom - 50);
      await tester.tapAt(bottomRightTap);
      await tester.pump();
      expect(scoreBCount, 2, reason: 'Tapping near bottom-right corner should score for Player B');
    });

    testWidgets('Tennis: Tapping anywhere inside top or bottom court increments points', (tester) async {
      int scoreACount = 0;
      int scoreBCount = 0;

      final state = TennisMatchState.initial(
        playerA1Name: 'Federer',
        playerB1Name: 'Nadal',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 600,
                child: TennisCourtCard(
                  matchState: state,
                  onScoreA: () => scoreACount++,
                  onScoreB: () => scoreBCount++,
                  onUndo: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(TennisCourtCard);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);

      // Tap near top-left edge (Player A)
      final topLeftTap = Offset(cardRect.left + 35, cardRect.top + 45);
      await tester.tapAt(topLeftTap);
      await tester.pump();
      expect(scoreACount, 1, reason: 'Tapping top-left of tennis court scores for Player A');

      // Tap near top-right edge (Player A)
      final topRightTap = Offset(cardRect.right - 35, cardRect.top + 45);
      await tester.tapAt(topRightTap);
      await tester.pump();
      expect(scoreACount, 2, reason: 'Tapping top-right of tennis court scores for Player A');

      // Tap near bottom-left edge (Player B)
      final bottomLeftTap = Offset(cardRect.left + 35, cardRect.bottom - 45);
      await tester.tapAt(bottomLeftTap);
      await tester.pump();
      expect(scoreBCount, 1, reason: 'Tapping bottom-left of tennis court scores for Player B');

      // Tap near bottom-right edge (Player B)
      final bottomRightTap = Offset(cardRect.right - 35, cardRect.bottom - 45);
      await tester.tapAt(bottomRightTap);
      await tester.pump();
      expect(scoreBCount, 2, reason: 'Tapping bottom-right of tennis court scores for Player B');
    });

    testWidgets('Table Tennis: Tapping anywhere inside top or bottom court increments points', (tester) async {
      int scoreACount = 0;
      int scoreBCount = 0;

      final state = TableTennisMatchState.initial(
        playerA1Name: 'Ma Long',
        playerB1Name: 'Fan Zhendong',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 600,
                child: TableTennisCourtCard(
                  matchState: state,
                  onScoreA: () => scoreACount++,
                  onScoreB: () => scoreBCount++,
                  onUndo: () {},
                  onToggleSide: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(TableTennisCourtCard);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);

      // Tap near top-left edge (Player A)
      final topLeftTap = Offset(cardRect.left + 30, cardRect.top + 40);
      await tester.tapAt(topLeftTap);
      await tester.pump();
      expect(scoreACount, 1, reason: 'Tapping top-left of table tennis scores for Player A');

      // Tap near bottom-left edge (Player B)
      final bottomLeftTap = Offset(cardRect.left + 30, cardRect.bottom - 40);
      await tester.tapAt(bottomLeftTap);
      await tester.pump();
      expect(scoreBCount, 1, reason: 'Tapping bottom-left of table tennis scores for Player B');
    });

    testWidgets('Volleyball: Tapping anywhere inside top or bottom court increments points', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VolleyballScoreScreen(
              teamAName: 'Thunder',
              teamBName: 'Lightning',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial score is 0 - 0
      expect(find.text('0'), findsNWidgets(2));

      // Tap near top-left of screen (top half / Team A, far from center text)
      await tester.tapAt(const Offset(40, 150));
      await tester.pumpAndSettle();

      // Team A score should now be 1
      expect(find.text('1'), findsOneWidget);

      // Tap near top-right of screen (top half / Team A)
      await tester.tapAt(const Offset(360, 200));
      await tester.pumpAndSettle();

      // Team A score should now be 2
      expect(find.text('2'), findsOneWidget);

      // Tap near bottom-left of screen (bottom half / Team B)
      await tester.tapAt(const Offset(40, 650));
      await tester.pumpAndSettle();

      // Team B score should now be 1 (Team A is 2, Team B is 1)
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap near bottom-right of screen (bottom half / Team B)
      await tester.tapAt(const Offset(360, 700));
      await tester.pumpAndSettle();

      // Both should have 2
      expect(find.text('2'), findsNWidgets(2));
    });
  });
}
