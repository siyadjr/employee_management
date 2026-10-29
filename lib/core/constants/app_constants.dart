class AppRoutes {
  static const String initial = '/';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String leave = '/leave';
  static const String applyLeave = '/leave/apply';
  static const String settings = '/settings';
}

class AppConstants {
  static const String appName = 'REBS HRMS';
   
  // Default Configurable Office Coordinates (REBS HQ)
  static const double defaultOfficeLatitude = 10.028282; // Configured Office Location
  static const double defaultOfficeLongitude = 76.336596;
  static const double maxAllowedGeofenceRadiusMeters = 200.0;
  
  static const String companyTimezone = 'Asia/Kolkata';
  
  // Storage Keys
  static const String keyCachedEmployee = 'cached_employee';
  static const String keyCachedAttendanceHistory = 'cached_attendance_history';
  static const String keyPendingAttendanceEvents = 'pending_attendance_events';
  static const String keyCachedLeaves = 'cached_leaves';
  static const String keySimulatedLocation = 'simulated_location_mode';

  // Configurable Workspace Keys
  static const String keyOfficeLatitude = 'config_office_lat';
  static const String keyOfficeLongitude = 'config_office_lng';
  static const String keyOfficeRadius = 'config_office_radius';
  static const String keyOfficeStartTime = 'config_office_start_time'; // e.g. "09:00"
  static const String keyOfficeEndTime = 'config_office_end_time';     // e.g. "18:00"
}
