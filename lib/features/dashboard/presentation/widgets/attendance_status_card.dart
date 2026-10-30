import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_management/core/theme/app_colors.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';

class AttendanceStatusCard extends StatelessWidget {
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration duration;
  final bool isActionInProgress;
  final Future<void> Function()? onCheckIn;
  final Future<void> Function()? onCheckOut;

  const AttendanceStatusCard({
    super.key,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    required this.duration,
    this.isActionInProgress = false,
    this.onCheckIn,
    this.onCheckOut,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a');
    final statusColor = status == AttendanceStatus.checkedIn
        ? AppColors.success
        : status == AttendanceStatus.checkedOut
            ? AppColors.info
            : AppColors.textSecondary;

    final statusText = status == AttendanceStatus.checkedIn
        ? 'Checked In'
        : status == AttendanceStatus.checkedOut
            ? 'Checked Out'
            : 'Not Checked In';

    final canCheckIn = status == AttendanceStatus.notCheckedIn;
    final canCheckOut = status == AttendanceStatus.checkedIn;

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
                  "Today's Attendance",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn(
                  'Check-In',
                  checkInTime != null ? timeFmt.format(checkInTime!) : '--:--',
                  Icons.login_rounded,
                ),
                _buildTimeColumn(
                  'Check-Out',
                  checkOutTime != null ? timeFmt.format(checkOutTime!) : '--:--',
                  Icons.logout_rounded,
                ),
                _buildTimeColumn(
                  'Working Hours',
                  _formatDuration(duration),
                  Icons.schedule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: canCheckIn && !isActionInProgress ? onCheckIn : null,
                    icon: isActionInProgress && canCheckIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: canCheckOut && !isActionInProgress ? onCheckOut : null,
                    icon: isActionInProgress && canCheckOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
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

  Widget _buildTimeColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
