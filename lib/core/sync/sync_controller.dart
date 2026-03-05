import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_database.dart';
import '../storage/db_providers.dart';

enum SyncState { online, offline, syncing, needsSync }

class SyncStatus {
  final SyncState state;
  final int pendingItems;
  final DateTime? lastSync;

  SyncStatus({required this.state, required this.pendingItems, this.lastSync});

  SyncStatus copyWith({
    SyncState? state,
    int? pendingItems,
    DateTime? lastSync,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingItems: pendingItems ?? this.pendingItems,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatus &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          pendingItems == other.pendingItems &&
          lastSync == other.lastSync;

  @override
  int get hashCode =>
      state.hashCode ^ pendingItems.hashCode ^ lastSync.hashCode;
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
      return SyncStatusNotifier(ref.watch(appDatabaseProvider));
    });

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final AppDatabase _db;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  Timer? _pendingCheckTimer;

  SyncStatusNotifier(this._db)
    : super(SyncStatus(state: SyncState.online, pendingItems: 0)) {
    _init();
  }

  void _init() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        if (state.state != SyncState.offline) {
          state = state.copyWith(state: SyncState.offline);
        }
      } else {
        if (state.state == SyncState.offline) {
          state = state.copyWith(state: SyncState.online);
        }
        _checkPendingItems();
      }
    });

    // Controllo periodico degli elementi pendenti - Frequenza ridotta per performance
    _pendingCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkPendingItems(),
    );
    _checkPendingItems();
  }

  Future<void> _checkPendingItems() async {
    final unsyncedResponses = await _db.countUnsyncedResponses();
    final unsyncedAttachments = await _db.countUnsyncedAttachments();
    final unsyncedSignatures = await _db.countUnsyncedSignatures();

    final total = unsyncedResponses + unsyncedAttachments + unsyncedSignatures;

    final newState = state.state != SyncState.offline
        ? (total > 0 ? SyncState.needsSync : SyncState.online)
        : SyncState.offline;

    if (state.state != newState || state.pendingItems != total) {
      state = state.copyWith(state: newState, pendingItems: total);
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _pendingCheckTimer?.cancel();
    super.dispose();
  }
}
