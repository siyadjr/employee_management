import 'package:flutter/material.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/core/navigation/main_navigation_shell.dart';
import 'package:employee_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:employee_management/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:employee_management/features/leave/presentation/screens/leave_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationShell(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case AppRoutes.attendance:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AttendanceScreen(),
        );

      case AppRoutes.leave:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LeaveScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
