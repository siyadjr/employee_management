import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:employee_management/core/network/mock_http_client.dart';
import 'package:employee_management/features/employee/domain/models/employee.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';
import 'package:employee_management/features/leave/domain/models/leave_request.dart';

class ApiService {
  final http.Client client;
  static const String baseUrl = 'https://api.rebs-hrms.local/v1';

  ApiService({http.Client? client}) : client = client ?? MockHttpClient();

  // 1. GET /employee/me
  Future<Employee> getEmployeeProfile() async {
    final response = await client.get(Uri.parse('$baseUrl/employee/me'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Employee.fromJson(data['employee']);
    } else {
      throw Exception('Failed to load employee profile (${response.statusCode})');
    }
  }

  // 2. GET /attendance?month=YYYY-MM
  Future<List<DailyAttendanceRecord>> getAttendanceHistory({String? month}) async {
    final uri = Uri.parse('$baseUrl/attendance${month != null ? '?month=$month' : ''}');
    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List records = data['records'];
      return records.map((e) => DailyAttendanceRecord.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load attendance history (${response.statusCode})');
    }
  }

  // 3. POST /attendance/events
  Future<Map<String, dynamic>> submitAttendanceEvent(AttendanceEvent event) async {
    final response = await client.post(
      Uri.parse('$baseUrl/attendance/events'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(event.toJson()),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else if (response.statusCode == 409 || response.statusCode == 400) {
      throw AttendanceConflictException(data['message'] ?? 'Attendance conflict or invalid order.');
    } else {
      throw Exception(data['message'] ?? 'Failed to submit attendance (${response.statusCode})');
    }
  }

  // 4. GET /leave/balance
  Future<Map<String, double>> getLeaveBalance() async {
    final response = await client.get(Uri.parse('$baseUrl/leave/balance'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'casual': (data['casualLeaveBalance'] as num).toDouble(),
        'sick': (data['sickLeaveBalance'] as num).toDouble(),
      };
    } else {
      throw Exception('Failed to fetch leave balance (${response.statusCode})');
    }
  }

  // 5. GET /leave/requests
  Future<List<LeaveRequest>> getLeaveRequests() async {
    final response = await client.get(Uri.parse('$baseUrl/leave/requests'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['requests'];
      return list.map((e) => LeaveRequest.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch leave requests (${response.statusCode})');
    }
  }

  // 6. POST /leave/requests
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    final response = await client.post(
      Uri.parse('$baseUrl/leave/requests'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return LeaveRequest.fromJson(data['request']);
    } else {
      throw Exception(data['message'] ?? 'Server rejected leave application (${response.statusCode})');
    }
  }
}

class AttendanceConflictException implements Exception {
  final String message;
  AttendanceConflictException(this.message);

  @override
  String toString() => message;
}
