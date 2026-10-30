import 'package:flutter/material.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';

class WorkspaceConfigProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  double _officeLatitude = AppConstants.defaultOfficeLatitude;
  double _officeLongitude = AppConstants.defaultOfficeLongitude;
  double _geofenceRadius = AppConstants.maxAllowedGeofenceRadiusMeters;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isDetectingLocation = false;

  WorkspaceConfigProvider(this._storage) {
    _loadConfig();
  }

  bool get isDetectingLocation => _isDetectingLocation;
  void setIsDetectingLocation(bool value) {
    _isDetectingLocation = value;
    notifyListeners();
  }

  double get officeLatitude => _officeLatitude;
  double get officeLongitude => _officeLongitude;
  double get geofenceRadius => _geofenceRadius;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;

  String get startTimeFormatted => _formatTime(_startTime);
  String get endTimeFormatted => _formatTime(_endTime);

  void _loadConfig() {
    _officeLatitude = _storage.getOfficeLatitude();
    _officeLongitude = _storage.getOfficeLongitude();
    _geofenceRadius = _storage.getOfficeRadius();
    _startTime = _parseTime(_storage.getOfficeStartTime(), const TimeOfDay(hour: 9, minute: 0));
    _endTime = _parseTime(_storage.getOfficeEndTime(), const TimeOfDay(hour: 18, minute: 0));
    notifyListeners();
  }

  Future<void> updateOfficeCoordinates({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    _officeLatitude = latitude;
    _officeLongitude = longitude;
    _geofenceRadius = radius;

    await _storage.saveOfficeLatitude(latitude);
    await _storage.saveOfficeLongitude(longitude);
    await _storage.saveOfficeRadius(radius);
    notifyListeners();
  }

  Future<void> updateOfficeHours({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    _startTime = startTime;
    _endTime = endTime;

    await _storage.saveOfficeStartTime(_formatTime(startTime));
    await _storage.saveOfficeEndTime(_formatTime(endTime));
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _officeLatitude = AppConstants.defaultOfficeLatitude;
    _officeLongitude = AppConstants.defaultOfficeLongitude;
    _geofenceRadius = AppConstants.maxAllowedGeofenceRadiusMeters;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 18, minute: 0);

    await _storage.saveOfficeLatitude(_officeLatitude);
    await _storage.saveOfficeLongitude(_officeLongitude);
    await _storage.saveOfficeRadius(_geofenceRadius);
    await _storage.saveOfficeStartTime('09:00');
    await _storage.saveOfficeEndTime('18:00');
    notifyListeners();
  }

  TimeOfDay _parseTime(String timeStr, TimeOfDay fallback) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
