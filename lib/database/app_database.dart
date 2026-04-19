import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

/// The central Drift database for the Storybook app.
///
/// Currently manages the [SyncQueues] table used by the offline-first
/// sync engine. Additional tables should be registered here as the
/// data layer grows.
@DriftDatabase(tables: [SyncQueues])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bump this version whenever the schema changes and provide a
  /// migration strategy in [migration].
  @override
  int get schemaVersion => 1;

  /// Opens a persistent SQLite database stored in the app's documents
  /// directory.
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'storybook.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
