import 'package:flutter/material.dart';
import 'package:employee_management/core/utils/location_service.dart';

class LocationGeofenceCard extends StatelessWidget {
  final LocationCheckResult? locationResult;
  final LocationSimulationOption mode;
  final VoidCallback onOpenReviewerSettings;

  const LocationGeofenceCard({
    super.key,
    required this.locationResult,
    required this.mode,
    required this.onOpenReviewerSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isWithin = locationResult?.isWithinRange ?? (mode == LocationSimulationOption.atOffice);
    final dist = locationResult?.distanceMeters ?? (mode == LocationSimulationOption.atOffice ? 15.0 : 350.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isWithin ? Icons.check_circle : Icons.warning_rounded,
                      color: isWithin ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isWithin ? 'Within Office Geofence' : 'Outside Office Geofence',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isWithin ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onOpenReviewerSettings,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Simulate'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Distance to HQ: ${dist.toStringAsFixed(1)}m (Max allowed: 200m)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Mode: ${_modeName(mode)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  String _modeName(LocationSimulationOption m) {
    switch (m) {
      case LocationSimulationOption.atOffice:
        return 'Simulated At Office (<20m)';
      case LocationSimulationOption.outsideOffice:
        return 'Simulated Outside Office (~350m)';
      case LocationSimulationOption.realDeviceGps:
        return 'Real Device Hardware GPS';
    }
  }
}
