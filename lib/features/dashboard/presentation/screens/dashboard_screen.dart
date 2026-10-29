import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/widgets/reviewer_settings_modal.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/employee_header_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/attendance_status_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/dashboard_geofence_status_card.dart';
import 'package:employee_management/features/dashboard/presentation/widgets/recent_attendance_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: sync.pendingCount > 0,
                    label: Text('${sync.pendingCount}'),
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
      body: _buildBody(context, dash, att, sync, empId),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DashboardProvider dash,
    AttendanceProvider att,
    SyncRepository sync,
    String empId,
  ) {
    if (dash.state == DashboardViewState.loading && dash.employee == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dash.state == DashboardViewState.error && dash.employee == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
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
            onRefreshLocation: () => att.locationService.verifyCurrentLocation(),
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
              }
            },
            onCheckOut: () async {
              final ok = await att.checkOut(empId);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check-out logged!')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildLeaveBalanceCard(emp),
          const SizedBox(height: 16),
          const Text(
            'Recent Attendance History',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.errorMessage!,
              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
            ),
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
            Container(width: 1, height: 35, color: Colors.grey.shade300),
            _buildBalanceItem('Sick Leave', '${emp.sickLeaveBalance} days'),
            Container(width: 1, height: 35, color: Colors.grey.shade300),
            _buildBalanceItem('Total Balance', '${emp.totalLeaveBalance} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
