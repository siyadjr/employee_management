import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:employee_management/core/network/mock_api_config.dart';

class MockHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  // In-memory server database simulation for demo employee
  static final Map<String, dynamic> _serverDb = {
    'employee': {
      'id': 'EMP-1042',
      'name': 'Alex Mercer',
      'department': 'Core Platform Engineering',
      'casualLeaveBalance': 12.0,
      'sickLeaveBalance': 6.0,
    },
    'office_location': {
      'name': 'Tech HQ',
      'latitude': 10.028282,
      'longitude': 76.336596,
      'radiusMeters': 200.0,
      'timezone': 'Asia/Kolkata',
    },
    // Set of received event IDs to guarantee idempotency
    'processed_event_ids': <String>{},
    // Server-side attendance records by date (YYYY-MM-DD)
    'attendance_records': <String, Map<String, dynamic>>{
      '2026-10-27': {
        'date': '2026-10-27',
        'checkInTime': '2026-10-27T09:12:00.000Z',
        'checkOutTime': '2026-10-27T18:05:00.000Z',
        'status': 'synced',
      },
      '2026-10-26': {
        'date': '2026-10-26',
        'checkInTime': '2026-10-26T09:05:00.000Z',
        'checkOutTime': '2026-10-26T17:50:00.000Z',
        'status': 'synced',
      },
      '2026-10-25': {
        'date': '2026-10-25',
        'checkInTime': '2026-10-25T08:55:00.000Z',
        'checkOutTime': '2026-10-25T17:30:00.000Z',
        'status': 'synced',
      },
    },
    'leave_requests': <Map<String, dynamic>>[
      {
        'id': 'LV-901',
        'employeeId': 'EMP-1042',
        'type': 'casual',
        'startDate': '2026-11-02T00:00:00.000Z',
        'endDate': '2026-11-03T00:00:00.000Z',
        'reason': 'Family event and personal work',
        'status': 'approved',
        'appliedAt': '2026-10-20T10:00:00.000Z',
      }
    ],
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;

    // Check scenario simulations
    if (MockApiConfig.scenario == MockNetworkScenario.slowNetwork) {
      await Future.delayed(const Duration(milliseconds: 3500));
      // Simulate client timeout
      throw TimeoutException('Simulated network timeout connecting to REBS API');
    }

    if (MockApiConfig.scenario == MockNetworkScenario.serverError) {
      await Future.delayed(Duration(milliseconds: MockApiConfig.simulatedDelayMs));
      return _buildResponse(
        statusCode: 500,
        body: {'error': 'InternalServerError', 'message': 'Simulated REBS server crash (500)'},
      );
    }

    // Default network latency
    await Future.delayed(Duration(milliseconds: MockApiConfig.simulatedDelayMs));

    // Handle Routes
    // 1. GET /employee/me
    if (request.method == 'GET' && path.endsWith('/employee/me')) {
      return _buildResponse(
        statusCode: 200,
        body: {
          'employee': _serverDb['employee'],
          'office': _serverDb['office_location'],
        },
      );
    }

    // 2. GET /attendance?month=YYYY-MM
    if (request.method == 'GET' && path.contains('/attendance')) {
      final records = (_serverDb['attendance_records'] as Map<String, dynamic>)
          .values
          .toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return _buildResponse(
        statusCode: 200,
        body: {'records': records},
      );
    }

    // 3. POST /attendance/events (Check-In or Check-Out)
    if (request.method == 'POST' && path.endsWith('/attendance/events')) {
      if (MockApiConfig.scenario == MockNetworkScenario.duplicateAttendanceConflict) {
        return _buildResponse(
          statusCode: 409,
          body: {
            'error': 'DuplicateAttendanceConflict',
            'message': 'Attendance record already exists for this working date on server.',
          },
        );
      }

      final bodyString = await request.finalize().bytesToString();
      final body = jsonDecode(bodyString) as Map<String, dynamic>;

      final eventId = body['id'] as String;
      final type = body['type'] as String; // checkIn or checkOut
      final timestamp = DateTime.parse(body['timestamp'] as String);
      final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

      final processedIds = _serverDb['processed_event_ids'] as Set<String>;

      // Idempotency check: If server already processed this exact event ID, acknowledge gracefully
      if (processedIds.contains(eventId)) {
        return _buildResponse(
          statusCode: 200,
          body: {
            'message': 'Event already processed (Idempotent replay)',
            'eventId': eventId,
            'status': 'synced',
          },
        );
      }

      final attendanceRecords = _serverDb['attendance_records'] as Map<String, dynamic>;
      final existingRecord = attendanceRecords[dateKey] ?? {'date': dateKey, 'status': 'synced'};

      if (type == 'checkIn') {
        if (existingRecord['checkInTime'] != null) {
          // Already checked in today
          return _buildResponse(
            statusCode: 409,
            body: {
              'error': 'AlreadyCheckedIn',
              'message': 'Employee is already checked in for date $dateKey.',
            },
          );
        }
        existingRecord['checkInTime'] = timestamp.toIso8601String();
      } else if (type == 'checkOut') {
        if (existingRecord['checkInTime'] == null) {
          return _buildResponse(
            statusCode: 400,
            body: {
              'error': 'InvalidCheckOutOrder',
              'message': 'Cannot check out without an active check-in for date $dateKey.',
            },
          );
        }
        if (existingRecord['checkOutTime'] != null) {
          return _buildResponse(
            statusCode: 409,
            body: {
              'error': 'AlreadyCheckedOut',
              'message': 'Employee is already checked out for date $dateKey.',
            },
          );
        }
        existingRecord['checkOutTime'] = timestamp.toIso8601String();
      }

      processedIds.add(eventId);
      attendanceRecords[dateKey] = existingRecord;

      return _buildResponse(
        statusCode: 201,
        body: {
          'message': 'Attendance event recorded successfully',
          'eventId': eventId,
          'record': existingRecord,
          'status': 'synced',
        },
      );
    }

    // 4. GET /leave/balance
    if (request.method == 'GET' && path.endsWith('/leave/balance')) {
      final emp = _serverDb['employee'] as Map<String, dynamic>;
      return _buildResponse(
        statusCode: 200,
        body: {
          'casualLeaveBalance': emp['casualLeaveBalance'],
          'sickLeaveBalance': emp['sickLeaveBalance'],
        },
      );
    }

    // 5. GET /leave/requests
    if (request.method == 'GET' && path.endsWith('/leave/requests')) {
      final leaves = _serverDb['leave_requests'] as List<Map<String, dynamic>>;
      return _buildResponse(
        statusCode: 200,
        body: {'requests': leaves},
      );
    }

    // 6. POST /leave/requests
    if (request.method == 'POST' && path.endsWith('/leave/requests')) {
      if (MockApiConfig.scenario == MockNetworkScenario.leaveValidationFailure) {
        return _buildResponse(
          statusCode: 422,
          body: {
            'error': 'UnprocessableEntity',
            'message': 'Server policy validation rejected this leave application.',
          },
        );
      }

      final bodyString = await request.finalize().bytesToString();
      final body = jsonDecode(bodyString) as Map<String, dynamic>;

      // Server-side validation repeat
      final reason = (body['reason'] as String?)?.replaceAll(RegExp(r'\s+'), '') ?? '';
      if (reason.length < 10) {
        return _buildResponse(
          statusCode: 422,
          body: {'error': 'InvalidReason', 'message': 'Reason must contain at least 10 non-whitespace characters.'},
        );
      }

      final leaves = _serverDb['leave_requests'] as List<Map<String, dynamic>>;
      leaves.insert(0, body);

      return _buildResponse(
        statusCode: 201,
        body: {
          'message': 'Leave application submitted successfully',
          'request': body,
        },
      );
    }

    // Pass-through fallback
    return _inner.send(request);
  }

  static void resetDb() {
    (_serverDb['processed_event_ids'] as Set<String>).clear();
    (_serverDb['attendance_records'] as Map<String, dynamic>).removeWhere((key, _) =>
        key != '2026-10-27' && key != '2026-10-26' && key != '2026-10-25');
  }

  http.StreamedResponse _buildResponse({
    required int statusCode,
    required Map<String, dynamic> body,
  }) {
    final bytes = utf8.encode(jsonEncode(body));
    final stream = Stream.value(bytes);
    return http.StreamedResponse(
      stream,
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
