import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_management/features/attendance/domain/models/attendance_event.dart';

class RecentAttendanceList extends StatelessWidget {
  final List<DailyAttendanceRecord> records;

  const RecentAttendanceList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No recent attendance records found.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final timeFmt = DateFormat('hh:mm a');

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: records.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final record = records[index];
          final inTime = record.checkInTime != null
              ? timeFmt.format(record.checkInTime!)
              : '--:--';
          final outTime = record.checkOutTime != null
              ? timeFmt.format(record.checkOutTime!)
              : '--:--';

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.calendar_today, size: 14, color: Color(0xFF1E3A8A)),
            ),
            title: Text(
              record.date,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text('In: $inTime | Out: $outTime'),
            trailing: _buildStatusBadge(record.status),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(SyncStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case SyncStatus.synced:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        text = 'Synced';
        break;
      case SyncStatus.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        text = 'Pending';
        break;
      case SyncStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
