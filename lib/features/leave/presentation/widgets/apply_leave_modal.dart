import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/theme/app_colors.dart';
import 'package:employee_management/features/leave/domain/models/leave_request.dart';
import 'package:employee_management/features/leave/presentation/providers/leave_provider.dart';

class ApplyLeaveModal extends StatefulWidget {
  final String employeeId;
  final double availableBalance;

  const ApplyLeaveModal({
    super.key,
    required this.employeeId,
    required this.availableBalance,
  });

  static void show(BuildContext context, String employeeId, double availableBalance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ApplyLeaveModal(
        employeeId: employeeId,
        availableBalance: availableBalance,
      ),
    );
  }

  @override
  State<ApplyLeaveModal> createState() => _ApplyLeaveModalState();
}

class _ApplyLeaveModalState extends State<ApplyLeaveModal> {
  final _formKey = GlobalKey<FormState>();
  LeaveType _selectedType = LeaveType.casual;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaveProv = context.watch<LeaveProvider>();
    final days = _endDate.difference(_startDate).inDays + 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply for Leave',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LeaveType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Leave Type'),
              items: const [
                DropdownMenuItem(value: LeaveType.casual, child: Text('Casual Leave')),
                DropdownMenuItem(value: LeaveType.sick, child: Text('Sick Leave')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date', style: TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                    trailing: const Icon(Icons.calendar_today, size: 16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End Date', style: TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                    trailing: const Icon(Icons.calendar_today, size: 16),
                    onTap: () async {
                      final initial = _endDate.isBefore(_startDate) ? _startDate : _endDate;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                ),
              ],
            ),
            Text(
              'Total Days: $days (Balance available: ${widget.availableBalance})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (at least 10 non-whitespace characters)',
                hintText: 'Describe reason for leave',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: leaveProv.isSubmitting
                    ? null
                    : () async {
                        final ok = await leaveProv.applyLeave(
                          employeeId: widget.employeeId,
                          type: _selectedType,
                          startDate: _startDate,
                          endDate: _endDate,
                          reason: _reasonController.text,
                          availableBalance: widget.availableBalance,
                        );
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leave applied successfully!')),
                          );
                        } else if (!ok && context.mounted && leaveProv.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.errorText,
                              content: Text(leaveProv.errorMessage!),
                            ),
                          );
                        }
                      },
                child: leaveProv.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
