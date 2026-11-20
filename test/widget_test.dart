import 'package:flashdeck/models/review_grade.dart';
import 'package:flashdeck/widgets/empty_state.dart';
import 'package:flashdeck/widgets/flip_card.dart';
import 'package:flashdeck/widgets/grade_buttons.dart';
import 'package:flashdeck/widgets/stat_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pure-widget smoke tests. The full app boot (home screen) loads from
/// the ffi SQLite database on a background isolate, whose responses are
/// not delivered to futures started inside the widget-test zone in this
/// environment — so the boot path is covered by the repository/service
/// tests instead, and these tests verify the UI pieces render and react.
void main() {
  testWidgets('EmptyState shows title, message and action button',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.style_outlined,
            title: 'No decks yet',
            message: 'Create your first deck.',
            actionLabel: 'Create a deck',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create your first deck.'), findsOneWidget);
    await tester.tap(find.text('Create a deck'));
    expect(tapped, isTrue);
  });

  testWidgets('GradeButtons shows all four grades and reports taps',
      (tester) async {
    ReviewGrade? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradeButtons(
            onGrade: (grade) => tapped = grade,
            intervals: const {
              ReviewGrade.again: '1d',
              ReviewGrade.hard: '1d',
              ReviewGrade.good: '6d',
              ReviewGrade.easy: '8d',
            },
          ),
        ),
      ),
    );
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('6d'), findsOneWidget);
    await tester.tap(find.text('Good'));
    expect(tapped, ReviewGrade.good);
  });

  testWidgets('StatChip shows value and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [StatChip(label: 'Day streak', value: '7')],
          ),
        ),
      ),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Day streak'), findsOneWidget);
  });

  testWidgets('FlipCard shows the front, flips to the back on tap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlipCard(
            front: 'What is 2 + 2?',
            back: '4',
            hint: 'Tap to reveal',
          ),
        ),
      ),
    );
    expect(find.text('What is 2 + 2?'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    await tester.tap(find.text('What is 2 + 2?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4'), findsOneWidget);
  });
}
