import 'package:flashdeck/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db.dart';

void main() {
  setUpAll(() {
    initTestDb();
  });

  setUp(() async {
    await resetTestDb();
  });

  tearDown(resetTestDb);

  testWidgets('home shows empty state when no decks exist',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await tester.pumpWidget(const FlashDeckApp());
    await tester.pumpAndSettle();
    expect(find.text('FlashDeck'), findsOneWidget);
    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create a deck'), findsWidgets);
  });
}
