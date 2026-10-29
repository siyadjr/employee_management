import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/widgets/reviewer_settings_modal.dart';
import 'package:employee_management/features/attendance/data/sync_repository.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/attendance/presentation/widgets/location_geofence_card.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/settings/presentation/providers/workspace_config_provider.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final att = context.watch<AttendanceProvider>();
    final sync = context.watch<SyncRepository>();
    final dash = context.watch<DashboardProvider>();
    final empId = dash.employee?.id ?? 'EMP-1042';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Check-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Reviewer Controls',
            onPressed: () => ReviewerSettingsModal.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          LocationGeofenceCard(
            locationResult: att.lastLocationCheck,
            mode: att.locationService.currentSimulationMode,
            onOpenReviewerSettings: () => ReviewerSettingsModal.show(context),
          ),
          const SizedBox(height: 16),
          _buildOfficeShiftBanner(context),
          const SizedBox(height: 16),
          if (att.errorMessage != null) ...[
            _buildErrorBanner(context, att),
            const SizedBox(height: 16),
          ],
          _buildActionCard(context, att, sync, empId),
          const SizedBox(height: 16),
          _buildPendingQueueCard(sync),
        ],
      ),
    );
  }

  Widget _buildOfficeShiftBanner(BuildContext context) {
    final storage = context.watch<AttendanceProvider>().locationService;
    // Read workspace config
    final configProv = context.watch<WorkspaceConfigProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: Colors.indigo.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configured Shift: ${configProv.startTimeFormatted} — ${configProv.endTimeFormatted}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.indigo.shade900,
                  ),
                ),
                Text(
                  'HQ: ${configProv.officeLatitude.toStringAsFixed(4)}, ${configProv.officeLongitude.toStringAsFixed(4)} (Radius: ${configProv.geofenceRadius.toStringAsFixed(0)}m)',
                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, AttendanceProvider att) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.errorMessage!,
              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => att.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    AttendanceProvider att,
    SyncRepository sync,
    String empId,
  ) {
    final canCheckIn = att.todayStatus == AttendanceStatus.notCheckedIn;
    final canCheckOut = att.todayStatus == AttendanceStatus.checkedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Attendance Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              canCheckIn
                  ? 'Record your check-in timestamp & GPS location'
                  : canCheckOut
                      ? 'You are currently checked in. Tap Check-Out to complete.'
                      : 'You have already checked out for today.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (att.checkInTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Check-In Time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '${att.checkInTime!.hour.toString().padLeft(2, '0')}:${att.checkInTime!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('Working Duration', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(att.workingDuration),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: att.todayStatus == AttendanceStatus.checkedIn
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: canCheckIn && !att.isActionInProgress
                        ? () async {
                            final ok = await att.checkIn(empId);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Check-in logged!')),
                              );
                            }
                          }
                        : null,
                    icon: att.isActionInProgress && canCheckIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                    ),
                    onPressed: canCheckOut && !att.isActionInProgress
                        ? () async {
                            final ok = await att.checkOut(empId);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Check-out logged!')),
                              );
                            }
                          }
                        : null,
                    icon: att.isActionInProgress && canCheckOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Check Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingQueueCard(SyncRepository sync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offline Sync Queue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${sync.pendingCount} pending',
                  style: TextStyle(
                    color: sync.pendingCount > 0 ? Colors.amber.shade900 : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Actions logged while offline survive app close/restarts and sync automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
