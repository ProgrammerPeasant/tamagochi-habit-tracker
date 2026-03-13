import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncStateView>(
  (ref) => SyncController(),
);

class SyncController extends StateNotifier<SyncStateView> {
  SyncController() : super(const SyncStateView());

  final SyncService _service = SyncService();

  Future<void> sync() async {
    if (state.isSyncing) {
      return;
    }
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final result = await _service.syncNow();
      state = state.copyWith(
        isSyncing: false,
        lastCursor: result.cursor,
        lastSyncedAt: DateTime.now().toUtc(),
      );
    } catch (error) {
      state = state.copyWith(isSyncing: false, error: error.toString());
    }
  }
}

class SyncStateView {
  final bool isSyncing;
  final String? lastCursor;
  final DateTime? lastSyncedAt;
  final String? error;

  const SyncStateView({
    this.isSyncing = false,
    this.lastCursor,
    this.lastSyncedAt,
    this.error,
  });

  SyncStateView copyWith({
    bool? isSyncing,
    String? lastCursor,
    DateTime? lastSyncedAt,
    String? error,
  }) {
    return SyncStateView(
      isSyncing: isSyncing ?? this.isSyncing,
      lastCursor: lastCursor ?? this.lastCursor,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error,
    );
  }
}
