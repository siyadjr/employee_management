import 'package:flutter_test/flutter_test.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/mock_api_config.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';

void main() {
  late ApiService apiService;

  setUp(() {
    MockApiConfig.setScenario(MockNetworkScenario.normal);
    MockApiConfig.simulatedDelayMs = 0; // fast tests
    apiService = ApiService();
  });

  test('GET /employee/me returns preconfigured employee Alex Mercer', () async {
    final employee = await apiService.getEmployeeProfile();
    expect(employee.id, equals('EMP-1042'));
    expect(employee.name, equals('Alex Mercer'));
    expect(employee.totalLeaveBalance, equals(18.0));
  });

  test('POST /attendance/events records check-in and guarantees idempotency on retry', () async {
    final event = AttendanceEvent(
      id: 'event-test-uuid-001',
      employeeId: 'EMP-1042',
      type: AttendanceEventType.checkIn,
      timestamp: DateTime.parse('2026-10-28T09:00:00.000Z'),
      latitude: 12.971598,
      longitude: 77.594562,
    );

    // First attempt -> created
    final res1 = await apiService.submitAttendanceEvent(event);
    expect(res1['status'], equals('synced'));

    // Second retry with same eventId -> returns idempotent 200 without duplicate conflict
    final res2 = await apiService.submitAttendanceEvent(event);
    expect(res2['status'], equals('synced'));
    expect(res2['message'], contains('Idempotent replay'));
  });

  test('POST /attendance/events enforces server duplicate conflict scenario when simulated', () async {
    MockApiConfig.setScenario(MockNetworkScenario.duplicateAttendanceConflict);

    final event = AttendanceEvent(
      id: 'event-conflict-test',
      employeeId: 'EMP-1042',
      type: AttendanceEventType.checkIn,
      timestamp: DateTime.parse('2026-10-29T09:00:00.000Z'),
      latitude: 12.971598,
      longitude: 77.594562,
    );

    expect(
      () => apiService.submitAttendanceEvent(event),
      throwsA(isA<AttendanceConflictException>()),
    );
  });
}
