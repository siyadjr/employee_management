import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:employee_management/core/network/mock_api_config.dart';
import 'package:employee_management/core/utils/location_service.dart';
import 'package:employee_management/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:employee_management/features/settings/presentation/providers/workspace_config_provider.dart';

class ConfigureScreen extends StatefulWidget {
  const ConfigureScreen({super.key});

  @override
  State<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends State<ConfigureScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<WorkspaceConfigProvider>();
    _latController = TextEditingController(text: config.officeLatitude.toString());
    _lngController = TextEditingController(text: config.officeLongitude.toString());
    _radiusController = TextEditingController(text: config.geofenceRadius.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentDeviceCoordinates() async {
    setState(() => _isDetectingLocation = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated to your device current GPS coordinates!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch current location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _saveLocationConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());
    final radius = double.parse(_radiusController.text.trim());

    final config = context.read<WorkspaceConfigProvider>();
    await config.updateOfficeCoordinates(
      latitude: lat,
      longitude: lng,
      radius: radius,
    );

    // Refresh attendance provider to recalculate distance against new office
    if (mounted) {
      await context.read<AttendanceProvider>().refreshLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.teal,
          content: Text('Office location & geofence updated across the app!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<WorkspaceConfigProvider>();
    final att = context.watch<AttendanceProvider>();
    final currentSimMode = att.locationService.currentSimulationMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              await config.resetToDefaults();
              _latController.text = config.officeLatitude.toString();
              _lngController.text = config.officeLongitude.toString();
              _radiusController.text = config.geofenceRadius.toStringAsFixed(0);
              if (context.mounted) {
                await context.read<AttendanceProvider>().refreshLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset all settings to default values.')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildOfficeLocationSection(context, config),
          const SizedBox(height: 16),
          _buildOfficeHoursSection(context, config),
          const SizedBox(height: 16),
          _buildSimulationSection(context, att, currentSimMode),
          const SizedBox(height: 16),
          _buildNetworkScenariosSection(),
        ],
      ),
    );
  }

  Widget _buildOfficeLocationSection(BuildContext context, WorkspaceConfigProvider config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Office Coordinates & Geofence',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (_isDetectingLocation)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      tooltip: 'Use My Current GPS',
                      onPressed: _useCurrentDeviceCoordinates,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Change office coordinates to test geofencing anywhere in the world.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num < -90 || num > 90) return 'Invalid (-90 to 90)';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num < -180 || num > 180) return 'Invalid (-180 to 180)';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Allowed Geofence Radius (metres)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: 'm',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveLocationConfig,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save & Apply Location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeHoursSection(BuildContext context, WorkspaceConfigProvider config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time_filled_rounded, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Office Working Hours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Company shift start and end times for daily work duration calculation.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shift Start', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      config.startTimeFormatted,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.schedule, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: config.startTime,
                      );
                      if (picked != null) {
                        await config.updateOfficeHours(
                          startTime: picked,
                          endTime: config.endTime,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shift End', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      config.endTimeFormatted,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.schedule, size: 18),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: config.endTime,
                      );
                      if (picked != null) {
                        await config.updateOfficeHours(
                          startTime: config.startTime,
                          endTime: picked,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSection(
    BuildContext context,
    AttendanceProvider att,
    LocationSimulationOption currentSimMode,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.satellite_alt_rounded, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Simulation Testing Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Quickly simulate being inside or outside the configured office location.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 20),
            RadioListTile<LocationSimulationOption>(
              title: const Text('Simulate Inside Office (< 20m)'),
              subtitle: const Text('Permits check-in & check-out'),
              value: LocationSimulationOption.atOffice,
              groupValue: currentSimMode,
              onChanged: (opt) async {
                if (opt != null) {
                  await att.locationService.setSimulationMode(opt);
                  await att.refreshLocation();
                  setState(() {});
                }
              },
            ),
            RadioListTile<LocationSimulationOption>(
              title: const Text('Simulate Outside Office (~350m)'),
              subtitle: const Text('Blocks check-in with outside error'),
              value: LocationSimulationOption.outsideOffice,
              groupValue: currentSimMode,
              onChanged: (opt) async {
                if (opt != null) {
                  await att.locationService.setSimulationMode(opt);
                  await att.refreshLocation();
                  setState(() {});
                }
              },
            ),
            RadioListTile<LocationSimulationOption>(
              title: const Text('Real Device Hardware GPS'),
              subtitle: const Text('Uses physical GPS sensors'),
              value: LocationSimulationOption.realDeviceGps,
              groupValue: currentSimMode,
              onChanged: (opt) async {
                if (opt != null) {
                  await att.locationService.setSimulationMode(opt);
                  await att.refreshLocation();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkScenariosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wifi_tethering_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Mock API Network Condition',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Simulate backend faults to test offline queue & error resiliency.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 20),
            ValueListenableBuilder<MockNetworkScenario>(
              valueListenable: MockApiConfig.notifier,
              builder: (context, activeScenario, _) {
                return Column(
                  children: MockNetworkScenario.values.map((sc) {
                    final isSelected = activeScenario == sc;
                    return RadioListTile<MockNetworkScenario>(
                      title: Text(
                        MockApiConfig.getScenarioTitle(sc),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        MockApiConfig.getScenarioDescription(sc),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      value: sc,
                      groupValue: activeScenario,
                      selected: isSelected,
                      onChanged: (newSc) {
                        if (newSc != null) {
                          MockApiConfig.setScenario(newSc);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to: ${MockApiConfig.getScenarioTitle(newSc)}'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
