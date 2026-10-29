import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/network/mock_api_config.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';

class ReviewerSettingsModal extends StatefulWidget {
  const ReviewerSettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReviewerSettingsModal(),
    );
  }

  @override
  State<ReviewerSettingsModal> createState() => _ReviewerSettingsModalState();
}

class _ReviewerSettingsModalState extends State<ReviewerSettingsModal> {
  @override
  Widget build(BuildContext context) {
    final attendanceProv = context.watch<AttendanceProvider>();
    final currentLocMode = attendanceProv.locationService.currentSimulationMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reviewer & Simulation Controls',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Toggle GPS locations & mock API scenarios easily.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const Divider(height: 24),
          const Text(
            'Location Simulation Mode (Geofence: 200m)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SegmentedButton<LocationSimulationOption>(
            segments: const [
              ButtonSegment(
                value: LocationSimulationOption.atOffice,
                label: Text('At Office\n(<20m)', textAlign: TextAlign.center),
                icon: Icon(Icons.business),
              ),
              ButtonSegment(
                value: LocationSimulationOption.outsideOffice,
                label: Text('Outside\n(~350m)', textAlign: TextAlign.center),
                icon: Icon(Icons.wrong_location_outlined),
              ),
              ButtonSegment(
                value: LocationSimulationOption.realDeviceGps,
                label: Text('Device\nGPS', textAlign: TextAlign.center),
                icon: Icon(Icons.my_location),
              ),
            ],
            selected: {currentLocMode},
            onSelectionChanged: (set) async {
              await attendanceProv.locationService.setSimulationMode(set.first);
              await attendanceProv.refreshLocation();
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Mock API Network Condition',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MockNetworkScenario>(
            initialValue: MockApiConfig.scenario,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: MockNetworkScenario.normal,
                child: Text('Normal (200 OK)'),
              ),
              DropdownMenuItem(
                value: MockNetworkScenario.slowNetwork,
                child: Text('Timeout / Slow Network'),
              ),
              DropdownMenuItem(
                value: MockNetworkScenario.serverError,
                child: Text('Server Error (500)'),
              ),
              DropdownMenuItem(
                value: MockNetworkScenario.duplicateAttendanceConflict,
                child: Text('Duplicate Conflict (409)'),
              ),
              DropdownMenuItem(
                value: MockNetworkScenario.leaveValidationFailure,
                child: Text('Leave Validation Rejection (422)'),
              ),
            ],
            onChanged: (sc) {
              if (sc != null) {
                MockApiConfig.setScenario(sc);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }
}
