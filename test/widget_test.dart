import 'package:flashdeck/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  setUpAll(initTestDb);

  setUp(resetTestDb);

  tearDown(resetTestDb);

  testWidgets('home shows empty state when no decks exist',
      (tester) async {
    await tester.pumpWidget(const FlashDeckApp());
    // Manual pumps instead of pumpAndSettle: the loading spinner is an
    // infinite animation, and the ffi database open needs real time.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('FlashDeck'), findsOneWidget);
    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create a deck'), findsWidgets);
  });
}
