enum LeaveType { casual, sick }

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  final String id;
  final String employeeId;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.appliedAt,
  });

  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status.name,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      type: LeaveType.values.byName(json['type'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String,
      status: LeaveStatus.values.byName(json['status'] as String),
      appliedAt: DateTime.parse(json['appliedAt'] as String),
    );
  }
}
