import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/core/navigation/app_router.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/core/theme/app_theme.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/leave/presentation/providers/leave_provider.dart';
import 'package:employee_management/features/settings/presentation/providers/workspace_config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await LocalStorageService.init();
  final apiService = ApiService();
  final networkInfo = NetworkInfo();
  final locationService = LocationService(storage);

  final syncRepository = SyncRepository(
    apiService: apiService,
    storage: storage,
    networkInfo: networkInfo,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: syncRepository),
        ChangeNotifierProvider(
          create: (_) => WorkspaceConfigProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            apiService: apiService,
            storage: storage,
            networkInfo: networkInfo,
            syncRepo: syncRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(
            syncRepo: syncRepository,
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
      child: const RebsHrmsApp(),
    ),
  );
}

class RebsHrmsApp extends StatelessWidget {
  const RebsHrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
