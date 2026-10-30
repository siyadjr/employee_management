import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/theme/app_colors.dart';
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
    // Read workspace config
    final configProv = context.watch<WorkspaceConfigProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configured Shift: ${configProv.startTimeFormatted} — ${configProv.endTimeFormatted}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'HQ: ${configProv.officeLatitude.toStringAsFixed(4)}, ${configProv.officeLongitude.toStringAsFixed(4)} (Radius: ${configProv.geofenceRadius.toStringAsFixed(0)}m)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.errorMessage!,
              style: const TextStyle(color: AppColors.errorTextDark, fontSize: 13),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (att.checkInTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Check-In Time', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '${att.checkInTime!.hour.toString().padLeft(2, '0')}:${att.checkInTime!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.borderLight),
                    Column(
                      children: [
                        const Text('Working Duration', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(att.workingDuration),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: att.todayStatus == AttendanceStatus.checkedIn
                                ? AppColors.success
                                : AppColors.info,
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
                      backgroundColor: AppColors.success,
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
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
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
                    color: sync.pendingCount > 0 ? AppColors.warningTextDark : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Actions logged while offline survive app close/restarts and sync automatically.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
