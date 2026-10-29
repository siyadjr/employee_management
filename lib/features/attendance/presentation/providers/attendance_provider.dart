import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';

enum AttendanceStatus { notCheckedIn, checkedIn, checkedOut }

class AttendanceProvider extends ChangeNotifier {
  final SyncRepository _syncRepo;
  final LocationService _locationService;
  final LocalStorageService _storage;
  final _uuid = const Uuid();

  AttendanceStatus _todayStatus = AttendanceStatus.notCheckedIn;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  bool _isActionInProgress = false;
  String? _errorMessage;
  LocationCheckResult? _lastLocationCheck;
  Timer? _ticker;

  AttendanceProvider({
    required SyncRepository syncRepo,
    required LocationService locationService,
    required LocalStorageService storage,
  })  : _syncRepo = syncRepo,
        _locationService = locationService,
        _storage = storage {
    _restoreTodayAttendance();
    _syncRepo.addListener(_restoreTodayAttendance);
    refreshLocation();
    _startTicker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_todayStatus == AttendanceStatus.checkedIn) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _syncRepo.removeListener(_restoreTodayAttendance);
    super.dispose();
  }

  Future<void> refreshLocation() async {
    try {
      _lastLocationCheck = await _locationService.verifyCurrentLocation();
      notifyListeners();
    } catch (_) {}
  }

  AttendanceStatus get todayStatus => _todayStatus;
  DateTime? get checkInTime => _checkInTime;
  DateTime? get checkOutTime => _checkOutTime;
  bool get isActionInProgress => _isActionInProgress;
  String? get errorMessage => _errorMessage;
  LocationCheckResult? get lastLocationCheck => _lastLocationCheck;
  LocationService get locationService => _locationService;

  Duration get workingDuration {
    if (_checkInTime == null) return Duration.zero;
    final end = _checkOutTime ?? DateTime.now();
    return end.difference(_checkInTime!);
  }

  void _restoreTodayAttendance() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Check pending queue first
    for (final event in _syncRepo.pendingQueue) {
      final eventDate =
          '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}';
      if (eventDate == todayStr) {
        if (event.type == AttendanceEventType.checkIn) {
          _checkInTime = event.timestamp;
          _todayStatus = AttendanceStatus.checkedIn;
        } else if (event.type == AttendanceEventType.checkOut) {
          _checkOutTime = event.timestamp;
          _todayStatus = AttendanceStatus.checkedOut;
        }
      }
    }

    // 2. Check cached history
    final history = _storage.getCachedAttendanceHistory();
    for (final record in history) {
      if (record.date == todayStr) {
        if (record.checkInTime != null) {
          _checkInTime = record.checkInTime;
          _todayStatus = AttendanceStatus.checkedIn;
        }
        if (record.checkOutTime != null) {
          _checkOutTime = record.checkOutTime;
          _todayStatus = AttendanceStatus.checkedOut;
        }
      }
    }
    notifyListeners();
  }

  Future<bool> checkIn(String employeeId) async {
    if (_isActionInProgress) return false;
    if (_todayStatus != AttendanceStatus.notCheckedIn) {
      _errorMessage = 'An employee can check in only once per working day.';
      notifyListeners();
      return false;
    }

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loc = await _locationService.verifyCurrentLocation();
      _lastLocationCheck = loc;

      if (!loc.isWithinRange) {
        _errorMessage =
            loc.errorMessage ?? 'Check-in failed: Outside permitted office area.';
        _isActionInProgress = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final event = AttendanceEvent(
        id: _uuid.v4(),
        employeeId: employeeId,
        type: AttendanceEventType.checkIn,
        timestamp: now,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );

      _checkInTime = now;
      _todayStatus = AttendanceStatus.checkedIn;
      
      // Update local cached history immediately so it persists across restarts
      _saveLocalDailyAttendance(
        dateStr: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        checkInTime: now,
        checkOutTime: null,
      );

      await _syncRepo.enqueueEvent(event);
      _isActionInProgress = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error during check-in: $e';
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  void _saveLocalDailyAttendance({
    required String dateStr,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    final history = _storage.getCachedAttendanceHistory();
    final idx = history.indexWhere((r) => r.date == dateStr);
    if (idx >= 0) {
      final existing = history[idx];
      history[idx] = DailyAttendanceRecord(
        date: dateStr,
        checkInTime: checkInTime ?? existing.checkInTime,
        checkOutTime: checkOutTime ?? existing.checkOutTime,
        status: existing.status,
      );
    } else {
      history.insert(
        0,
        DailyAttendanceRecord(
          date: dateStr,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          status: SyncStatus.pending,
        ),
      );
    }
    _storage.saveAttendanceHistory(history);
  }

  Future<bool> checkOut(String employeeId) async {
    if (_isActionInProgress) return false;
    if (_todayStatus != AttendanceStatus.checkedIn) {
      _errorMessage = 'Check-out is permitted only after an active check-in.';
      notifyListeners();
      return false;
    }

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loc = await _locationService.verifyCurrentLocation();
      _lastLocationCheck = loc;

      if (!loc.isWithinRange) {
        _errorMessage =
            loc.errorMessage ?? 'Check-out failed: Outside permitted office area.';
        _isActionInProgress = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final event = AttendanceEvent(
        id: _uuid.v4(),
        employeeId: employeeId,
        type: AttendanceEventType.checkOut,
        timestamp: now,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );

      _checkOutTime = now;
      _todayStatus = AttendanceStatus.checkedOut;

      _saveLocalDailyAttendance(
        dateStr: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        checkInTime: _checkInTime,
        checkOutTime: now,
      );

      await _syncRepo.enqueueEvent(event);
      _isActionInProgress = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error during check-out: $e';
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
