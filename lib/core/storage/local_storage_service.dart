import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/features/employee/domain/models/employee.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';
import 'package:employee_management/features/leave/domain/models/leave_request.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Employee Profile
  Future<void> saveEmployee(Employee employee) async {
    await _prefs.setString(
      AppConstants.keyCachedEmployee,
      jsonEncode(employee.toJson()),
    );
  }

  Employee? getCachedEmployee() {
    final raw = _prefs.getString(AppConstants.keyCachedEmployee);
    if (raw == null) return null;
    try {
      return Employee.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // Attendance History Cache
  Future<void> saveAttendanceHistory(List<DailyAttendanceRecord> records) async {
    final list = records.map((r) => r.toJson()).toList();
    await _prefs.setString(
      AppConstants.keyCachedAttendanceHistory,
      jsonEncode(list),
    );
  }

  List<DailyAttendanceRecord> getCachedAttendanceHistory() {
    final raw = _prefs.getString(AppConstants.keyCachedAttendanceHistory);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => DailyAttendanceRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Pending Attendance Events Queue (Persists across restarts)
  Future<void> savePendingEvents(List<AttendanceEvent> events) async {
    final list = events.map((e) => e.toJson()).toList();
    await _prefs.setString(
      AppConstants.keyPendingAttendanceEvents,
      jsonEncode(list),
    );
  }

  List<AttendanceEvent> getPendingEvents() {
    final raw = _prefs.getString(AppConstants.keyPendingAttendanceEvents);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => AttendanceEvent.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Leave Requests Cache
  Future<void> saveLeaves(List<LeaveRequest> leaves) async {
    final list = leaves.map((l) => l.toJson()).toList();
    await _prefs.setString(AppConstants.keyCachedLeaves, jsonEncode(list));
  }

  List<LeaveRequest> getCachedLeaves() {
    final raw = _prefs.getString(AppConstants.keyCachedLeaves);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => LeaveRequest.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Location Simulation Mode Cache
  Future<void> saveSimulationMode(String mode) async {
    await _prefs.setString(AppConstants.keySimulatedLocation, mode);
  }

  String getSimulationMode() {
    return _prefs.getString(AppConstants.keySimulatedLocation) ?? 'at_office';
  }

  // Office Coordinates & Geofence
  Future<void> saveOfficeLatitude(double lat) async =>
      _prefs.setDouble(AppConstants.keyOfficeLatitude, lat);

  double getOfficeLatitude() =>
      _prefs.getDouble(AppConstants.keyOfficeLatitude) ??
      AppConstants.defaultOfficeLatitude;

  Future<void> saveOfficeLongitude(double lng) async =>
      _prefs.setDouble(AppConstants.keyOfficeLongitude, lng);

  double getOfficeLongitude() =>
      _prefs.getDouble(AppConstants.keyOfficeLongitude) ??
      AppConstants.defaultOfficeLongitude;

  Future<void> saveOfficeRadius(double radius) async =>
      _prefs.setDouble(AppConstants.keyOfficeRadius, radius);

  double getOfficeRadius() =>
      _prefs.getDouble(AppConstants.keyOfficeRadius) ??
      AppConstants.maxAllowedGeofenceRadiusMeters;

  // Office Working Hours
  Future<void> saveOfficeStartTime(String time) async =>
      _prefs.setString(AppConstants.keyOfficeStartTime, time);

  String getOfficeStartTime() =>
      _prefs.getString(AppConstants.keyOfficeStartTime) ?? '09:00';

  Future<void> saveOfficeEndTime(String time) async =>
      _prefs.setString(AppConstants.keyOfficeEndTime, time);

  String getOfficeEndTime() =>
      _prefs.getString(AppConstants.keyOfficeEndTime) ?? '18:00';
}
