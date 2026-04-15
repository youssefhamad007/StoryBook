import 'package:drift/drift.dart';

/// Drift table definition for the local synchronization queue.
///
/// Stores user actions (CRUD operations) performed while offline.
/// These actions are batched and pushed to Supabase when connectivity
/// is restored.
///
/// Possible [actionType] values:
///   - 'CREATE_STORY'
///   - 'UPDATE_STORY'
///   - 'DELETE_STORY'
///   - 'CREATE_STORY_PAGE'
///   - 'UPDATE_STORY_PAGE'
///   - 'DELETE_STORY_PAGE'
///   - 'UPDATE_PROFILE'
///   - 'TOGGLE_FAVORITE'
///
/// Possible [status] values:
///   - 'pending'    → Queued, waiting for sync.
///   - 'processing' → Currently being sent to Supabase.
///   - 'failed'     → Sync attempt failed, will retry.
class SyncQueues extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// The type of action performed (e.g., 'CREATE_STORY', 'UPDATE_PROFILE').
  TextColumn get actionType => text()();

  /// JSON-encoded payload containing the data to sync with the backend.
  TextColumn get payload => text()();

  /// Current sync status: 'pending', 'processing', or 'failed'.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Timestamp of when the action was queued.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
