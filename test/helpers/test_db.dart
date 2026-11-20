import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flashdeck/data/database_helper.dart';

/// Initialises the ffi database factory so sqflite works in tests.
void initTestDb() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Closes and deletes the test database file for a clean slate.
Future<void> resetTestDb() async {
  await DatabaseHelper.instance.close();
  await deleteDatabase(p.join(await getDatabasesPath(), 'flashdeck.db'));
}
