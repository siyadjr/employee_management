import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:employee_management/features/leave/presentation/providers/leave_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen displays loading state and renders employee profile and sync badge', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();
    final apiService = ApiService();
    final networkInfo = MockNetworkInfo(connected: true);
    final locationService = LocationService(storage);

    final syncRepo = SyncRepository(
      apiService: apiService,
      storage: storage,
      networkInfo: networkInfo,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: syncRepo),
          ChangeNotifierProvider(
            create: (_) => DashboardProvider(
              apiService: apiService,
              storage: storage,
              networkInfo: networkInfo,
              syncRepo: syncRepo,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AttendanceProvider(
              syncRepo: syncRepo,
              locationService: locationService,
              storage: storage,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => LeaveProvider(
              apiService: apiService,
              storage: storage,
              networkInfo: networkInfo,
            ),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Initial pump shows screen title
    expect(find.text('REBS Dashboard'), findsOneWidget);

    // Settle frames to allow async mock HTTP responses to load
    await tester.pumpAndSettle();

    // Verify employee header and details rendered
    expect(find.text('Alex Mercer'), findsOneWidget);
    expect(find.text("Today's Attendance"), findsOneWidget);
    expect(find.text('Casual Leave'), findsOneWidget);

    // Scroll down to reveal recent attendance history
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Recent Attendance History'), findsOneWidget);
  });
}
