import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/mock_api_config.dart';
import 'package:employee_management/core/network/mock_http_client.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/leave/presentation/providers/leave_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late ApiService apiService;
  late MockNetworkInfo networkInfo;
  late SyncRepository syncRepo;
  late LocationService locationService;
  late AttendanceProvider attendanceProvider;
  late LeaveProvider leaveProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockHttpClient.resetDb();
    MockApiConfig.setScenario(MockNetworkScenario.normal);
    MockApiConfig.simulatedDelayMs = 0;
    storage = await LocalStorageService.init();
    apiService = ApiService();
    networkInfo = MockNetworkInfo(connected: true);
    syncRepo = SyncRepository(
      apiService: apiService,
      storage: storage,
      networkInfo: networkInfo,
    );
    locationService = LocationService(storage);
    attendanceProvider = AttendanceProvider(
      syncRepo: syncRepo,
      locationService: locationService,
      storage: storage,
    );
    leaveProvider = LeaveProvider(
      apiService: apiService,
      storage: storage,
      networkInfo: networkInfo,
    );
  });

  // Requirement 1: Check-out without check-in is rejected
  test('1. Check-out without check-in is rejected', () async {
    final result = await attendanceProvider.checkOut('EMP-1042');
    expect(result, isFalse);
    expect(
      attendanceProvider.errorMessage,
      contains('Check-out is permitted only after an active check-in'),
    );
  });

  // Requirement 2: Repeated submission or retry does not create duplicate attendance
  test('2. Repeated submission or retry does not create duplicate attendance', () async {
    final event = AttendanceEvent(
      id: 'fixed-uuid-101',
      employeeId: 'EMP-1042',
      type: AttendanceEventType.checkIn,
      timestamp: DateTime(2026, 10, 29, 9, 0),
      latitude: AppConstants.defaultOfficeLatitude,
      longitude: AppConstants.defaultOfficeLongitude,
    );

    final res1 = await apiService.submitAttendanceEvent(event);
    expect(res1['status'], equals('synced'));

    // Second retry with identical event ID
    final res2 = await apiService.submitAttendanceEvent(event);
    expect(res2['status'], equals('synced'));
    expect(res2['message'], contains('Idempotent replay'));
  });

  // Requirement 3: Pending attendance survives persistence and can be synchronized in order
  test('3. Pending attendance survives persistence and can be synchronized in order', () async {
    final testDate = DateTime(2026, 10, 30, 9, 0);
    final checkInEvent = AttendanceEvent(
      id: 'event-persist-in',
      employeeId: 'EMP-1042',
      type: AttendanceEventType.checkIn,
      timestamp: testDate,
      latitude: AppConstants.defaultOfficeLatitude,
      longitude: AppConstants.defaultOfficeLongitude,
    );
    final checkOutEvent = AttendanceEvent(
      id: 'event-persist-out',
      employeeId: 'EMP-1042',
      type: AttendanceEventType.checkOut,
      timestamp: testDate.add(const Duration(hours: 8)),
      latitude: AppConstants.defaultOfficeLatitude,
      longitude: AppConstants.defaultOfficeLongitude,
    );

    // Enqueue both events while offline
    networkInfo.connected = false;
    await syncRepo.enqueueEvent(checkInEvent);
    await syncRepo.enqueueEvent(checkOutEvent);

    // Simulate app process termination and restore from SharedPreferences
    final restoredStorage = await LocalStorageService.init();
    final persistedQueue = restoredStorage.getPendingEvents();

    expect(persistedQueue.length, equals(2));
    expect(persistedQueue.first.type, equals(AttendanceEventType.checkIn));
    expect(persistedQueue.last.type, equals(AttendanceEventType.checkOut));

    // Reconnect and synchronize pending events in sequential order
    networkInfo.connected = true;
    await syncRepo.syncPendingEvents();
    expect(syncRepo.pendingCount, equals(0));
  });

  // Requirement 4: Overlapping leave dates are rejected
  test('4. Overlapping leave dates are rejected', () async {
    await leaveProvider.loadLeaves();

    // In MockHttpClient, LV-901 is already approved for 2026-11-02 to 2026-11-03
    // Attempt overlapping request: Nov 02 - Nov 04
    final error = leaveProvider.validateLeaveForm(
      startDate: DateTime.parse('2026-11-02T00:00:00.000Z'),
      endDate: DateTime.parse('2026-11-04T00:00:00.000Z'),
      reason: 'Valid reason exceeding 10 characters',
      availableBalance: 12.0,
    );

    expect(error, isNotNull);
    expect(error, contains('overlap with an existing approved leave request'));
  });
}
