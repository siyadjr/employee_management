import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';

class SyncRepository extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storage;
  final INetworkInfo _networkInfo;

  List<AttendanceEvent> _pendingQueue = [];
  bool _isSyncing = false;
  String? _lastSyncError;

  SyncRepository({
    required ApiService apiService,
    required LocalStorageService storage,
    required INetworkInfo networkInfo,
  })  : _apiService = apiService,
        _storage = storage,
        _networkInfo = networkInfo {
    _loadQueueFromStorage();
    _listenToConnectivity();
  }

  List<AttendanceEvent> get pendingQueue => List.unmodifiable(_pendingQueue);
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  int get pendingCount =>
      _pendingQueue.where((e) => e.syncStatus == SyncStatus.pending).length;

  void _loadQueueFromStorage() {
    _pendingQueue = _storage.getPendingEvents();
    notifyListeners();
  }

  void _listenToConnectivity() {
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected && _pendingQueue.isNotEmpty && !_isSyncing) {
        syncPendingEvents();
      }
    });
  }

  Future<void> enqueueEvent(AttendanceEvent event) async {
    _pendingQueue.add(event);
    await _storage.savePendingEvents(_pendingQueue);
    notifyListeners();

    // Auto-attempt sync if online
    if (await _networkInfo.isConnected && !_isSyncing) {
      await syncPendingEvents();
    }
  }

  Future<void> syncPendingEvents() async {
    if (_isSyncing || _pendingQueue.isEmpty) return;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    // Sort to strictly preserve chronological check-in -> check-out ordering
    _pendingQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<AttendanceEvent> remaining = [];

    for (final event in _pendingQueue) {
      if (event.syncStatus == SyncStatus.synced) {
        remaining.add(event);
        continue;
      }

      try {
        await _apiService.submitAttendanceEvent(event);
        // Successfully synced
        final syncedEvent = event.copyWith(
          syncStatus: SyncStatus.synced,
          errorMessage: null,
        );
        remaining.add(syncedEvent);
      } on AttendanceConflictException catch (e) {
        // Server rejected due to existing attendance -> mark as rejected
        final rejectedEvent = event.copyWith(
          syncStatus: SyncStatus.rejected,
          errorMessage: e.message,
        );
        remaining.add(rejectedEvent);
      } catch (e) {
        // Network timeout, offline or temporary server error -> keep pending
        remaining.add(event);
        _lastSyncError = e.toString();
        break; // Stop sequential batch to maintain ordering
      }
    }

    _pendingQueue = remaining;
    await _storage.savePendingEvents(_pendingQueue);
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> clearSyncedEvents() async {
    _pendingQueue.removeWhere((e) => e.syncStatus == SyncStatus.synced);
    await _storage.savePendingEvents(_pendingQueue);
    notifyListeners();
  }
}
