import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:employee_management/core/theme/app_colors.dart';
import 'package:employee_management/core/widgets/reviewer_settings_modal.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/employee_header_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/attendance_status_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/dashboard_geofence_status_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/recent_attendance_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  _LocationBannerState _bannerState = _LocationBannerState.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLocationOnOpen());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleLocationOnOpen();
    }
  }

  Future<void> _handleLocationOnOpen() async {
    if (!mounted) return;
    final att = context.read<AttendanceProvider>();
    final locationService = att.locationService;
    final mode = locationService.currentSimulationMode;

    // Nothing to do if today is fully complete
    if (att.todayStatus == AttendanceStatus.checkedOut) {
      if (mounted) setState(() => _bannerState = _LocationBannerState.none);
      return;
    }

    // ALWAYS request location permission on launch regardless of simulation mode.
    // Permission is needed even in simulation mode so the user's device is ready
    // when they switch to real GPS mode later.
    await _requestLocationPermission(locationService);

    // After permission is handled, if simulation mode is active and no
    // error banner is showing, display the simulation info banner.
    if (mounted &&
        _bannerState == _LocationBannerState.none &&
        mode != LocationSimulationOption.realDeviceGps) {
      setState(() => _bannerState = _LocationBannerState.simulationActive);
    }
  }

  Future<void> _requestLocationPermission(LocationService locationService) async {
    try {
      // Step 1: Check if location services (GPS) are turned on.
      // If off, automatically open the location settings screen so the user
      // can enable it, then re-check when they return to the app.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _bannerState = _LocationBannerState.serviceOff);
        // Auto-open location settings so the user immediately sees the toggle
        await Geolocator.openLocationSettings();
        return;
      }

      // Step 2: Check and request location permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // This triggers the system permission dialog
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;

      if (permission == LocationPermission.deniedForever) {
        setState(() => _bannerState = _LocationBannerState.deniedForever);
      } else if (permission == LocationPermission.denied) {
        setState(() => _bannerState = _LocationBannerState.denied);
      } else {
        // Permission granted — silently refresh location check
        setState(() => _bannerState = _LocationBannerState.none);
        await context.read<AttendanceProvider>().refreshLocation();
      }
    } catch (e) {
      debugPrint('[Dashboard] Location permission error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final att = context.watch<AttendanceProvider>();
    final sync = context.watch<SyncRepository>();
    final empId = dash.employee?.id ?? 'EMP-1042';

    return Scaffold(
      appBar: AppBar(
        title: const Text('REBS Dashboard'),
        actions: [
          IconButton(
            icon: sync.isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Badge(
                    isLabelVisible: sync.pendingCount > 0,
                    label: Text(sync.pendingCount.toString()),
                    child: const Icon(Icons.sync_rounded),
                  ),
            tooltip: 'Sync Now',
            onPressed: sync.isSyncing
                ? null
                : () async {
                    await sync.syncPendingEvents();
                    await dash.loadDashboard();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(sync.lastSyncError ?? 'Sync complete!')),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Reviewer Controls',
            onPressed: () => ReviewerSettingsModal.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocationBanner(context, att),
          Expanded(child: _buildBody(context, dash, att, sync, empId)),
        ],
      ),
    );
  }

  Widget _buildLocationBanner(BuildContext context, AttendanceProvider att) {
    if (_bannerState == _LocationBannerState.none) return const SizedBox.shrink();
    if (att.todayStatus == AttendanceStatus.checkedOut) return const SizedBox.shrink();

    Color color;
    IconData icon;
    String message;
    String actionLabel;
    VoidCallback onAction;

    switch (_bannerState) {
      case _LocationBannerState.simulationActive:
        color = AppColors.info;
        icon = Icons.science_rounded;
        final modeName = att.locationService.currentSimulationMode ==
                LocationSimulationOption.atOffice
            ? 'At Office'
            : 'Outside Office';
        message =
            'Simulated location active ($modeName). Go to Configure tab to switch to Real GPS.';
        actionLabel = 'Got it';
        onAction = () => setState(() => _bannerState = _LocationBannerState.none);
        break;
      case _LocationBannerState.denied:
        color = AppColors.warning;
        icon = Icons.location_off_rounded;
        message = 'Location permission denied. Tap Allow to grant access for check-in/out.';
        actionLabel = 'Allow';
        onAction = () => _requestLocationPermission(att.locationService);
        break;
      case _LocationBannerState.deniedForever:
        color = AppColors.error;
        icon = Icons.location_disabled_rounded;
        message = 'Location permanently denied. Open device Settings to enable it.';
        actionLabel = 'Settings';
        onAction = () => Geolocator.openAppSettings();
        break;
      case _LocationBannerState.serviceOff:
        color = AppColors.error;
        icon = Icons.gps_off_rounded;
        message = 'Location services are off on your device. Enable GPS to check in.';
        actionLabel = 'Enable GPS';
        onAction = () => Geolocator.openLocationSettings();
        break;
      default:
        return const SizedBox.shrink();
    }

    return Material(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: color, fontSize: 12)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: onAction,
              child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
            ),
            if (_bannerState == _LocationBannerState.simulationActive)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: color,
                onPressed: () => setState(() => _bannerState = _LocationBannerState.none),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardProvider dash,
      AttendanceProvider att, SyncRepository sync, String empId) {
    if (dash.state == DashboardViewState.loading && dash.employee == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dash.state == DashboardViewState.error && dash.employee == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(dash.errorMessage ?? 'Unable to connect to server'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => dash.loadDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final emp = dash.employee!;
    return RefreshIndicator(
      onRefresh: () async {
        await sync.syncPendingEvents();
        await dash.loadDashboard();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          EmployeeHeaderCard(employee: emp, isOffline: dash.isOffline),
          const SizedBox(height: 12),
          DashboardGeofenceStatusCard(
            locationResult: att.lastLocationCheck,
            mode: att.locationService.currentSimulationMode,
            onOpenReviewerSettings: () => ReviewerSettingsModal.show(context),
            onRefreshLocation: () => att.refreshLocation(),
          ),
          const SizedBox(height: 12),
          if (att.errorMessage != null) ...[
            _buildErrorBanner(context, att),
            const SizedBox(height: 12),
          ],
          AttendanceStatusCard(
            status: att.todayStatus,
            checkInTime: att.checkInTime,
            checkOutTime: att.checkOutTime,
            duration: att.workingDuration,
            isActionInProgress: att.isActionInProgress,
            onCheckIn: () async {
              final ok = await att.checkIn(empId);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check-in logged!')),
                );
                setState(() => _bannerState = _LocationBannerState.none);
              }
            },
            onCheckOut: () async {
              final ok = await att.checkOut(empId);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check-out logged!')),
                );
                setState(() => _bannerState = _LocationBannerState.none);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildLeaveBalanceCard(emp),
          const SizedBox(height: 16),
          const Text('Recent Attendance History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RecentAttendanceList(records: dash.latestRecords),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, AttendanceProvider att) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(att.errorMessage!,
                style: const TextStyle(color: AppColors.errorTextDark, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => att.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCard(dynamic emp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBalanceItem('Casual Leave', '${emp.casualLeaveBalance} days'),
            Container(width: 1, height: 35, color: AppColors.borderLight),
            _buildBalanceItem('Sick Leave', '${emp.sickLeaveBalance} days'),
            Container(width: 1, height: 35, color: AppColors.borderLight),
            _buildBalanceItem('Total Balance', '${emp.totalLeaveBalance} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

enum _LocationBannerState { none, simulationActive, denied, deniedForever, serviceOff }
