enum AttendanceEventType { checkIn, checkOut }

enum SyncStatus { pending, synced, rejected }

class AttendanceEvent {
  final String id; // UUID for idempotency
  final String employeeId;
  final AttendanceEventType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final SyncStatus syncStatus;
  final String? errorMessage;

  AttendanceEvent({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.syncStatus = SyncStatus.pending,
    this.errorMessage,
  });

  AttendanceEvent copyWith({
    String? id,
    String? employeeId,
    AttendanceEventType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    SyncStatus? syncStatus,
    String? errorMessage,
  }) {
    return AttendanceEvent(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'syncStatus': syncStatus.name,
      'errorMessage': errorMessage,
    };
  }

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      type: AttendanceEventType.values.byName(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      syncStatus: SyncStatus.values.byName(json['syncStatus'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class DailyAttendanceRecord {
  final String date; // YYYY-MM-DD
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final SyncStatus status;

  DailyAttendanceRecord({
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = SyncStatus.synced,
  });

  Duration? get duration {
    if (checkInTime == null) return null;
    final end = checkOutTime ?? DateTime.now();
    return end.difference(checkInTime!);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status.name,
    };
  }

  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecord(
      date: json['date'] as String,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      status: SyncStatus.values.byName(json['status'] as String),
    );
  }
}
