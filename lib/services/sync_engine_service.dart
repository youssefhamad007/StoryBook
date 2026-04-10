import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

/// The core offline-to-online synchronization engine.
///
/// Responsible for draining the local [SyncQueues] table and pushing
/// queued actions to Supabase when the device regains connectivity.
///
/// **Usage:**
/// ```dart
/// final engine = SyncEngineService(
///   db: appDatabase,
///   supabase: Supabase.instance.client,
/// );
/// await engine.syncPendingActions();
/// ```
///
/// The engine is designed to be **fault-tolerant**: if an individual
/// record fails to sync, the error is caught and logged, and the loop
/// continues processing the remaining records.
class SyncEngineService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncEngineService({
    required AppDatabase db,
    required SupabaseClient supabase,
  })  : _db = db,
        _supabase = supabase;

  // -------------------------------------------------------------------------
  // Core Sync Method
  // -------------------------------------------------------------------------

  /// Fetches all 'pending' records from the local sync queue and attempts
  /// to push each one to Supabase.
  ///
  /// **Flow per record:**
  /// 1. Mark status as `'processing'`.
  /// 2. Parse the JSON payload.
  /// 3. Route to the appropriate Supabase operation based on `actionType`.
  /// 4. On success → **delete** the record from the local queue.
  /// 5. On failure → mark status as `'failed'` and continue.
  ///
  /// Returns a [SyncResult] summarizing what happened.
  Future<SyncResult> syncPendingActions() async {
    int successCount = 0;
    int failedCount = 0;

    // 1 — Fetch all pending records, ordered by creation time (FIFO).
    final pendingRecords = await (_db.select(_db.syncQueues)
          ..where((row) => row.status.equals('pending'))
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();

    if (pendingRecords.isEmpty) {
      log('No pending actions to sync.', name: 'SyncEngine');
      return SyncResult(total: 0, synced: 0, failed: 0);
    }

    log(
      'Starting sync: ${pendingRecords.length} pending action(s).',
      name: 'SyncEngine',
    );

    // 2 — Process each record individually.
    for (final record in pendingRecords) {
      try {
        // 2a — Mark as 'processing' so it isn't picked up by a concurrent run.
        await _updateStatus(record.id, 'processing');

        // 2b — Parse the JSON payload.
        final Map<String, dynamic> data =
            jsonDecode(record.payload) as Map<String, dynamic>;

        // 2c — Route to the correct Supabase operation.
        await _dispatch(record.actionType, data);

        // 2d — Success → remove from queue.
        await (_db.delete(_db.syncQueues)
              ..where((row) => row.id.equals(record.id)))
            .go();

        successCount++;

        log(
          'Synced [${record.actionType}] id=${record.id}',
          name: 'SyncEngine',
        );
      } catch (e) {
        // 2e — Failure → mark as 'failed', log, and continue.
        failedCount++;

        await _updateStatus(record.id, 'failed');

        log(
          'Failed to sync [${record.actionType}] id=${record.id}: $e',
          name: 'SyncEngine',
          level: 900, // Warning level
        );
      }
    }

    log(
      'Sync complete: $successCount synced, $failedCount failed.',
      name: 'SyncEngine',
    );

    return SyncResult(
      total: pendingRecords.length,
      synced: successCount,
      failed: failedCount,
    );
  }

  // -------------------------------------------------------------------------
  // Retry Failed Actions
  // -------------------------------------------------------------------------

  /// Resets all `'failed'` records back to `'pending'` so they are
  /// picked up in the next [syncPendingActions] cycle.
  Future<int> retryFailedActions() async {
    final count = await (_db.update(_db.syncQueues)
          ..where((row) => row.status.equals('failed')))
        .write(const SyncQueuesCompanion(status: Value('pending')));

    log('Reset $count failed action(s) to pending.', name: 'SyncEngine');
    return count;
  }

  // -------------------------------------------------------------------------
  // Pending Count (for UI badges, etc.)
  // -------------------------------------------------------------------------

  /// Returns the number of records still waiting to be synced
  /// (status = 'pending' or 'failed').
  Future<int> getPendingCount() async {
    final query = _db.select(_db.syncQueues)
      ..where(
        (row) =>
            row.status.equals('pending') | row.status.equals('failed'),
      );
    final results = await query.get();
    return results.length;
  }

  // -------------------------------------------------------------------------
  // Action Dispatcher (private)
  // -------------------------------------------------------------------------

  /// Routes a queued action to the correct Supabase table operation.
  ///
  /// Add new cases here as more features are built.
  Future<void> _dispatch(String actionType, Map<String, dynamic> data) async {
    switch (actionType) {
      // ── Stories ──────────────────────────────────────────────────────
      case 'CREATE_STORY':
        await _supabase.from('stories').insert(data);
        break;

      case 'UPDATE_STORY':
        final storyId = data.remove('id') as String;
        await _supabase.from('stories').update(data).eq('id', storyId);
        break;

      case 'DELETE_STORY':
        final storyId = data['id'] as String;
        await _supabase.from('stories').delete().eq('id', storyId);
        break;

      // ── Story Pages ─────────────────────────────────────────────────
      case 'CREATE_STORY_PAGE':
        await _supabase.from('story_pages').insert(data);
        break;

      case 'UPDATE_STORY_PAGE':
        final pageId = data.remove('id') as String;
        await _supabase.from('story_pages').update(data).eq('id', pageId);
        break;

      case 'DELETE_STORY_PAGE':
        final pageId = data['id'] as String;
        await _supabase.from('story_pages').delete().eq('id', pageId);
        break;

      // ── Profile ─────────────────────────────────────────────────────
      case 'UPDATE_PROFILE':
        final userId = data.remove('id') as String;
        await _supabase.from('profiles').update(data).eq('id', userId);
        break;

      // ── Favorites ───────────────────────────────────────────────────
      case 'TOGGLE_FAVORITE':
        final isFavorite = data['is_favorite'] as bool;
        if (isFavorite) {
          await _supabase.from('favorites').insert({
            'user_id': data['user_id'],
            'story_id': data['story_id'],
          });
        } else {
          await _supabase
              .from('favorites')
              .delete()
              .eq('user_id', data['user_id'] as String)
              .eq('story_id', data['story_id'] as String);
        }
        break;

      // ── Unknown ─────────────────────────────────────────────────────
      default:
        throw SyncEngineException(
          'Unknown actionType: "$actionType". '
          'Please add a handler in SyncEngineService._dispatch().',
        );
    }
  }

  // -------------------------------------------------------------------------
  // Helpers (private)
  // -------------------------------------------------------------------------

  /// Updates the [status] column of a sync queue record by its [id].
  Future<void> _updateStatus(int id, String status) async {
    await (_db.update(_db.syncQueues)
          ..where((row) => row.id.equals(id)))
        .write(SyncQueuesCompanion(status: Value(status)));
  }
}

// ---------------------------------------------------------------------------
// Sync Result
// ---------------------------------------------------------------------------

/// A simple data class summarizing the outcome of a sync cycle.
class SyncResult {
  final int total;
  final int synced;
  final int failed;

  const SyncResult({
    required this.total,
    required this.synced,
    required this.failed,
  });

  bool get isFullySuccessful => failed == 0;

  @override
  String toString() =>
      'SyncResult(total: $total, synced: $synced, failed: $failed)';
}

// ---------------------------------------------------------------------------
// Custom Exception
// ---------------------------------------------------------------------------

/// Exception thrown when the sync engine encounters an unrecoverable error.
class SyncEngineException implements Exception {
  final String message;

  const SyncEngineException(this.message);

  @override
  String toString() => 'SyncEngineException: $message';
}
