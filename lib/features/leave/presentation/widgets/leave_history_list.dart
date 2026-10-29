import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_management/features/leave/domain/models/leave_request.dart';

class LeaveHistoryList extends StatelessWidget {
  final List<LeaveRequest> leaves;

  const LeaveHistoryList({super.key, required this.leaves});

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No leave requests found.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final dateFmt = DateFormat('MMM dd, yyyy');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaves.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final req = leaves[index];
        final typeName = req.type == LeaveType.casual ? 'Casual Leave' : 'Sick Leave';
        final dates = '${dateFmt.format(req.startDate)} - ${dateFmt.format(req.endDate)}';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$typeName (${req.daysCount} days)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    _buildStatusChip(req.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dates, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  req.reason,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(LeaveStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case LeaveStatus.approved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case LeaveStatus.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case LeaveStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
