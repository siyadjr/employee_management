import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/network/mock_api_config.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';

class ReviewerSettingsModal extends StatefulWidget {
  const ReviewerSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
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
  bool _isApplying = false;

  Future<void> _onModeChanged(
    AttendanceProvider attendanceProv,
    LocationSimulationOption newOption,
  ) async {
    setState(() => _isApplying = true);
    try {
      await attendanceProv.locationService.setSimulationMode(newOption);
      await attendanceProv.refreshLocation();
      if (mounted) {
        final modeName = switch (newOption) {
          LocationSimulationOption.atOffice => 'At Office (<20m)',
          LocationSimulationOption.outsideOffice => 'Outside Office (~350m)',
          LocationSimulationOption.realDeviceGps => 'Device Hardware GPS',
        };
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Location updated to $modeName')),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  void _onNetworkScenarioChanged(MockNetworkScenario scenario) {
    MockApiConfig.setScenario(scenario);
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_tethering_rounded, color: Colors.lightBlueAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Network simulated: ${scenario.name}')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProv = context.watch<AttendanceProvider>();
    final currentLocMode = attendanceProv.locationService.currentSimulationMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reviewer Controls',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toggle GPS & mock API conditions',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _isApplying
                    ? null
                    : () async {
                        await attendanceProv.refreshLocation();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Done'),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location Simulation Mode (Geofence: 200m)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (_isApplying)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<LocationSimulationOption>(
              segments: const [
                ButtonSegment(
                  value: LocationSimulationOption.atOffice,
                  label: Text('At Office\n(<20m)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.business, size: 18),
                ),
                ButtonSegment(
                  value: LocationSimulationOption.outsideOffice,
                  label: Text('Outside\n(~350m)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.wrong_location_outlined, size: 18),
                ),
                ButtonSegment(
                  value: LocationSimulationOption.realDeviceGps,
                  label: Text('Device\nGPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.my_location, size: 18),
                ),
              ],
              selected: {currentLocMode},
              onSelectionChanged: _isApplying
                  ? null
                  : (set) async {
                      if (set.isNotEmpty) {
                        await _onModeChanged(attendanceProv, set.first);
                      }
                    },
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mock API Network Condition',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                _onNetworkScenarioChanged(sc);
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Apply Changes & Close', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isApplying
                  ? null
                  : () async {
                      await attendanceProv.refreshLocation();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

