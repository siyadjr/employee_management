import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:employee_management/core/constants/app_constants.dart';
import 'package:employee_management/core/storage/local_storage_service.dart';

enum LocationSimulationOption {
  atOffice, // At office (< 20m)
  outsideOffice, // Outside geofence (> 200m)
  realDeviceGps, // Actual device hardware GPS
}

class LocationCheckResult {
  final bool isWithinRange;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final String? errorMessage;

  LocationCheckResult({
    required this.isWithinRange,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    this.errorMessage,
  });
}

class LocationService {
  final LocalStorageService _storage;

  LocationService(this._storage);

  LocationSimulationOption get currentSimulationMode {
    final mode = _storage.getSimulationMode();
    switch (mode) {
      case 'outside_office':
        return LocationSimulationOption.outsideOffice;
      case 'real_gps':
        return LocationSimulationOption.realDeviceGps;
      case 'at_office':
      default:
        return LocationSimulationOption.atOffice;
    }
  }

  Future<void> setSimulationMode(LocationSimulationOption option) async {
    String value = 'at_office';
    if (option == LocationSimulationOption.outsideOffice) {
      value = 'outside_office';
    } else if (option == LocationSimulationOption.realDeviceGps) {
      value = 'real_gps';
    }
    await _storage.saveSimulationMode(value);
  }

  Future<LocationCheckResult> verifyCurrentLocation({
    double? officeLat,
    double? officeLng,
    double? radiusMeters,
  }) async {
    final targetOfficeLat = officeLat ?? _storage.getOfficeLatitude();
    final targetOfficeLng = officeLng ?? _storage.getOfficeLongitude();
    final targetRadius = radiusMeters ?? _storage.getOfficeRadius();
    final mode = currentSimulationMode;

    if (mode == LocationSimulationOption.atOffice) {
      // Simulate precisely 15 meters from current configured office center
      final simulatedLat = targetOfficeLat + 0.0001;
      final simulatedLng = targetOfficeLng + 0.0001;
      final dist = calculateDistance(
        simulatedLat,
        simulatedLng,
        targetOfficeLat,
        targetOfficeLng,
      );
      return LocationCheckResult(
        isWithinRange: dist <= targetRadius,
        distanceMeters: dist,
        latitude: simulatedLat,
        longitude: simulatedLng,
      );
    }

    if (mode == LocationSimulationOption.outsideOffice) {
      // Simulate ~350 meters away from configured office
      final simulatedLat = targetOfficeLat + 0.0035;
      final simulatedLng = targetOfficeLng + 0.0035;
      final dist = calculateDistance(
        simulatedLat,
        simulatedLng,
        targetOfficeLat,
        targetOfficeLng,
      );
      return LocationCheckResult(
        isWithinRange: dist <= targetRadius,
        distanceMeters: dist,
        latitude: simulatedLat,
        longitude: simulatedLng,
        errorMessage:
            'Outside office boundary (${dist.toStringAsFixed(0)}m away. Allowed: ${targetRadius.toStringAsFixed(0)}m).',
      );
    }

    // Real GPS Device checks
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationCheckResult(
        isWithinRange: false,
        distanceMeters: -1,
        latitude: 0,
        longitude: 0,
        errorMessage: 'Location services are disabled on this device.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationCheckResult(
          isWithinRange: false,
          distanceMeters: -1,
          latitude: 0,
          longitude: 0,
          errorMessage: 'Location permission was denied by the user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationCheckResult(
        isWithinRange: false,
        distanceMeters: -1,
        latitude: 0,
        longitude: 0,
        errorMessage:
            'Location permissions are permanently denied. Please enable in Settings.',
      );
    }

    final pos = await Geolocator.getCurrentPosition();
    final dist = calculateDistance(
      pos.latitude,
      pos.longitude,
      targetOfficeLat,
      targetOfficeLng,
    );

    return LocationCheckResult(
      isWithinRange: dist <= targetRadius,
      distanceMeters: dist,
      latitude: pos.latitude,
      longitude: pos.longitude,
      errorMessage: dist > targetRadius
          ? 'You are ${dist.toStringAsFixed(0)}m away from office (Allowed: ${targetRadius.toStringAsFixed(0)}m).'
          : null,
    );
  }

  // Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Pi / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * 1000 meters
  }
}
