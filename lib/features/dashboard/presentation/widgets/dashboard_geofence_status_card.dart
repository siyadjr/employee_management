import 'package:flutter/material.dart';
import 'package:employee_management/core/utils/location_service.dart';

class DashboardGeofenceStatusCard extends StatelessWidget {
  final LocationCheckResult? locationResult;
  final LocationSimulationOption mode;
  final VoidCallback onOpenReviewerSettings;
  final VoidCallback? onRefreshLocation;

  const DashboardGeofenceStatusCard({
    super.key,
    required this.locationResult,
    required this.mode,
    required this.onOpenReviewerSettings,
    this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isWithin =
        locationResult?.isWithinRange ??
        (mode == LocationSimulationOption.atOffice);
    final dist =
        locationResult?.distanceMeters ??
        (mode == LocationSimulationOption.atOffice ? 15.0 : 350.0);
    final error = locationResult?.errorMessage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isWithin
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        color: isWithin
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isWithin
                              ? 'Geofence:\nInside (<200m)'
                              : 'Geofence:\nOutside',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle( 
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isWithin
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRefreshLocation != null)
                      IconButton(
                        icon: const Icon(Icons.my_location, size: 16),
                        tooltip: 'Check Current GPS',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onRefreshLocation,
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onOpenReviewerSettings,
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text(
                        'Simulate',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Office: 10.028282, 76.336596 • Distance: ${dist < 0 ? 'Unknown' : '${dist.toStringAsFixed(1)}m'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
