import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_engine_service.dart';

/// Listens to network connectivity changes and automatically triggers
/// a sync cycle when the device regains a usable connection.
///
/// **Usage:**
/// ```dart
/// final service = ConnectivitySyncService(
///   syncEngineService: mySyncEngine,
/// );
/// service.startListening();
/// // ...
/// service.dispose(); // when no longer needed
/// ```
class ConnectivitySyncService {
  final SyncEngineService _syncEngineService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivitySyncService({
    required SyncEngineService syncEngineService,
    Connectivity? connectivity,
  })  : _syncEngineService = syncEngineService,
        _connectivity = connectivity ?? Connectivity();

  /// Starts listening to connectivity changes.
  ///
  /// When the device transitions to [ConnectivityResult.mobile] or
  /// [ConnectivityResult.wifi], the sync engine is triggered.
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    log('ConnectivitySyncService: listening for network changes.');
  }

  /// Handles connectivity change events.
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasConnection = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);

    if (hasConnection) {
      log(
        'ConnectivitySyncService: connection restored ($results). '
        'Triggering sync…',
      );
      try {
        final result = await _syncEngineService.syncPendingActions();
        log('ConnectivitySyncService: $result');
      } catch (e) {
        log(
          'ConnectivitySyncService: sync failed — $e',
          level: 900,
        );
      }
    }
  }

  /// Cancels the connectivity subscription and frees resources.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    log('ConnectivitySyncService: disposed.');
  }
}
