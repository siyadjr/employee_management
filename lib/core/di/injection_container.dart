import 'package:get_it/get_it.dart';
import 'package:employee_management/core/network/api_service.dart';
import 'package:employee_management/core/network/network_info.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/settings/presentation/providers/workspace_config_provider.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({
  LocalStorageService? storage,
  ApiService? apiService,
  INetworkInfo? networkInfo,
  LocationService? locationService,
  SyncRepository? syncRepository,
}) async {
  // 1. Storage Service (Async initialization if not supplied)
  if (!getIt.isRegistered<LocalStorageService>()) {
    final localStore = storage ?? await LocalStorageService.init();
    getIt.registerSingleton<LocalStorageService>(localStore);
  }

  // 2. Network Info Service
  if (!getIt.isRegistered<INetworkInfo>()) {
    getIt.registerLazySingleton<INetworkInfo>(() => networkInfo ?? NetworkInfo());
  }

  // 3. API Service
  if (!getIt.isRegistered<ApiService>()) {
    getIt.registerLazySingleton<ApiService>(() => apiService ?? ApiService());
  }

  // 4. Location Service
  if (!getIt.isRegistered<LocationService>()) {
    getIt.registerLazySingleton<LocationService>(
      () => locationService ?? LocationService(getIt<LocalStorageService>()),
    );
  }

  // 5. Offline Sync Repository
  if (!getIt.isRegistered<SyncRepository>()) {
    getIt.registerLazySingleton<SyncRepository>(
      () =>
          syncRepository ??
          SyncRepository(
            apiService: getIt<ApiService>(),
            storage: getIt<LocalStorageService>(),
            networkInfo: getIt<INetworkInfo>(),
          ),
    );
  }

  // 6. Workspace Config Provider
  if (!getIt.isRegistered<WorkspaceConfigProvider>()) {
    getIt.registerLazySingleton<WorkspaceConfigProvider>(
      () => WorkspaceConfigProvider(getIt<LocalStorageService>()),
    );
  }
}
