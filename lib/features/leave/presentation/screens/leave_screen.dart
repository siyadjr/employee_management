import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:employee_management/features/leave/presentation/providers/leave_provider.dart';
import 'package:employee_management/features/leave/presentation/widgets/apply_leave_modal.dart';
import 'package:employee_management/features/leave/presentation/widgets/leave_history_list.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaveProv = context.watch<LeaveProvider>();
    final dash = context.watch<DashboardProvider>();
    final emp = dash.employee;
    final empId = emp?.id ?? 'EMP-1042';
    final balance = emp?.totalLeaveBalance ?? 18.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ApplyLeaveModal.show(context, empId, balance),
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: RefreshIndicator(
        onRefresh: () => leaveProv.loadLeaves(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (leaveProv.errorMessage != null) ...[
              _buildErrorBanner(context, leaveProv),
              const SizedBox(height: 12),
            ],
            _buildBalanceBanner(balance),
            const SizedBox(height: 16),
            const Text(
              'My Leave Applications',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LeaveHistoryList(leaves: leaveProv.leaves),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBanner(double balance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.beach_access, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Total Balance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('$balance Days Available', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, LeaveProvider prov) {
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
          Expanded(child: Text(prov.errorMessage!, style: TextStyle(color: Colors.red.shade900, fontSize: 13))),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => prov.clearError()),
        ],
      ),
    );
  }
}
