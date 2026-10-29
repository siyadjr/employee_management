import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/features/leave/domain/models/leave_request.dart';

class LeaveProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storage;
  final INetworkInfo _networkInfo;
  final _uuid = const Uuid();

  List<LeaveRequest> _leaves = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  LeaveProvider({
    required ApiService apiService,
    required LocalStorageService storage,
    required INetworkInfo networkInfo,
  })  : _apiService = apiService,
        _storage = storage,
        _networkInfo = networkInfo {
    loadLeaves();
  }

  List<LeaveRequest> get leaves => List.unmodifiable(_leaves);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadLeaves() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Load cached leaves for offline viewing
    final cached = _storage.getCachedLeaves();
    if (cached.isNotEmpty) {
      _leaves = cached;
      notifyListeners();
    }

    // 2. Fetch fresh if online
    if (await _networkInfo.isConnected) {
      try {
        final serverLeaves = await _apiService.getLeaveRequests();
        _leaves = serverLeaves;
        await _storage.saveLeaves(serverLeaves);
      } catch (e) {
        _errorMessage = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  String? validateLeaveForm({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required double availableBalance,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    final endNormalized = DateTime(endDate.year, endDate.month, endDate.day);

    // Rule 1: Start date cannot be before current company date
    if (startNormalized.isBefore(today)) {
      return 'Start date cannot be in the past.';
    }

    // Rule 2: End date cannot be before start date
    if (endNormalized.isBefore(startNormalized)) {
      return 'End date cannot be earlier than start date.';
    }

    // Rule 3: Reason must contain at least 10 non-whitespace characters
    final nonWhitespaceChars = reason.replaceAll(RegExp(r'\s+'), '');
    if (nonWhitespaceChars.length < 10) {
      return 'Reason must contain at least 10 non-whitespace characters.';
    }

    // Rule 4: Requested days cannot exceed available balance
    final requestedDays = endNormalized.difference(startNormalized).inDays + 1;
    if (requestedDays > availableBalance) {
      return 'Requested days ($requestedDays) exceed available balance ($availableBalance).';
    }

    // Rule 5: Dates cannot overlap existing Pending or Approved request
    for (final req in _leaves) {
      if (req.status == LeaveStatus.pending || req.status == LeaveStatus.approved) {
        final reqStart = DateTime(req.startDate.year, req.startDate.month, req.startDate.day);
        final reqEnd = DateTime(req.endDate.year, req.endDate.month, req.endDate.day);

        final overlaps = !startNormalized.isAfter(reqEnd) && !endNormalized.isBefore(reqStart);
        if (overlaps) {
          return 'Selected dates overlap with an existing ${req.status.name} leave request.';
        }
      }
    }

    return null;
  }

  Future<bool> applyLeave({
    required String employeeId,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required double availableBalance,
  }) async {
    final valError = validateLeaveForm(
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      availableBalance: availableBalance,
    );

    if (valError != null) {
      _errorMessage = valError;
      notifyListeners();
      return false;
    }

    // Check connectivity requirement
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      _errorMessage = 'Leave submission requires an active internet connection.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newReq = LeaveRequest(
        id: 'LV-${_uuid.v4().substring(0, 6).toUpperCase()}',
        employeeId: employeeId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason.trim(),
        status: LeaveStatus.pending,
        appliedAt: DateTime.now(),
      );

      final created = await _apiService.submitLeaveRequest(newReq);
      _leaves.insert(0, created);
      await _storage.saveLeaves(_leaves);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = msg;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
