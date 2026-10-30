import 'package:flutter/material.dart';
import 'package:employee_management/core/theme/app_colors.dart';
import 'package:employee_management/features/employee/domain/models/employee.dart';

class EmployeeHeaderCard extends StatelessWidget {
  final Employee employee;
  final bool isOffline;

  const EmployeeHeaderCard({
    super.key,
    required this.employee,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    employee.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${employee.id} • ${employee.department}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOffline
                        ? AppColors.warningLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline ? Icons.wifi_off : Icons.wifi,
                        size: 13,
                        color: isOffline ? AppColors.warningText : AppColors.successText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOffline ? 'Offline' : 'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOffline
                              ? AppColors.warningText
                              : AppColors.successText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
