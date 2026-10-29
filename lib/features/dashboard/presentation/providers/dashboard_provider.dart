import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/features/employee/domain/models/employee.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';

enum DashboardViewState { loading, empty, content, error }

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storage;
  final INetworkInfo _networkInfo;
  final SyncRepository _syncRepo;

  DashboardViewState _state = DashboardViewState.loading;
  Employee? _employee;
  List<DailyAttendanceRecord> _latestRecords = [];
  bool _isOffline = false;
  String? _errorMessage;
  Timer? _ticker;

  DashboardProvider({
    required ApiService apiService,
    required LocalStorageService storage,
    required INetworkInfo networkInfo,
    required SyncRepository syncRepo,
  })  : _apiService = apiService,
        _storage = storage,
        _networkInfo = networkInfo,
        _syncRepo = syncRepo {
    _startTicker();
    _syncRepo.addListener(_onSyncRepoChanged);
    loadDashboard();
  }

  void _onSyncRepoChanged() {
    _mergePendingEventsIntoHistory();
    notifyListeners();
  }

  DashboardViewState get state => _state;
  Employee? get employee => _employee;
  List<DailyAttendanceRecord> get latestRecords => _latestRecords;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _mergePendingEventsIntoHistory() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    DateTime? todayIn;
    DateTime? todayOut;
    SyncStatus todayStatus = SyncStatus.synced;

    for (final event in _syncRepo.pendingQueue) {
      final evDate =
          '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}';
      if (evDate == todayStr) {
        if (event.type == AttendanceEventType.checkIn) todayIn = event.timestamp;
        if (event.type == AttendanceEventType.checkOut) todayOut = event.timestamp;
        todayStatus = event.syncStatus;
      }
    }

    if (todayIn != null || todayOut != null) {
      final existingIdx = _latestRecords.indexWhere((r) => r.date == todayStr);
      final todayRec = DailyAttendanceRecord(
        date: todayStr,
        checkInTime: todayIn,
        checkOutTime: todayOut,
        status: todayStatus,
      );

      if (existingIdx >= 0) {
        _latestRecords[existingIdx] = todayRec;
      } else {
        _latestRecords.insert(0, todayRec);
        if (_latestRecords.length > 5) {
          _latestRecords = _latestRecords.take(5).toList();
        }
      }
    }
  }

  Future<void> loadDashboard() async {
    _state = DashboardViewState.loading;
    _errorMessage = null;
    notifyListeners();

    // 1. Immediately load cache for offline availability
    final cachedEmp = _storage.getCachedEmployee();
    final cachedHistory = _storage.getCachedAttendanceHistory();
    if (cachedEmp != null) {
      _employee = cachedEmp;
      _latestRecords = List.from(cachedHistory.take(5));
      _mergePendingEventsIntoHistory();
      _state = _latestRecords.isEmpty ? DashboardViewState.empty : DashboardViewState.content;
      notifyListeners();
    }

    // 2. Fetch fresh data if connected
    final online = await _networkInfo.isConnected;
    _isOffline = !online;

    if (!online) {
      if (_employee == null) {
        _employee = Employee.defaultEmployee();
      }
      _mergePendingEventsIntoHistory();
      _state = _latestRecords.isEmpty ? DashboardViewState.empty : DashboardViewState.content;
      notifyListeners();
      return;
    }

    try {
      final emp = await _apiService.getEmployeeProfile();
      final history = await _apiService.getAttendanceHistory();

      _employee = emp;
      _latestRecords = List.from(history.take(5));

      await _storage.saveEmployee(emp);
      await _storage.saveAttendanceHistory(history);

      _mergePendingEventsIntoHistory();
      _state = _latestRecords.isEmpty ? DashboardViewState.empty : DashboardViewState.content;
      _isOffline = false;
      notifyListeners();
    } catch (e) {
      if (_employee == null) {
        _state = DashboardViewState.error;
        _errorMessage = e.toString();
      } else {
        _isOffline = true;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _syncRepo.removeListener(_onSyncRepoChanged);
    super.dispose();
  }
}
