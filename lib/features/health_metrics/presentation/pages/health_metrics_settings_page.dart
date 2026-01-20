import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../../../../core/injection_container.dart';
import '../../data/datasources/local/health_preferences_service.dart';
import '../../../../core/services/app_theme.dart';

class HealthMetricsSettingsPage extends StatefulWidget {
  const HealthMetricsSettingsPage({super.key});

  @override
  State<HealthMetricsSettingsPage> createState() =>
      _HealthMetricsSettingsPageState();
}

class _HealthMetricsSettingsPageState extends State<HealthMetricsSettingsPage> {
  final HealthPreferencesService _prefs = sl<HealthPreferencesService>();
  Map<HealthDataType, bool> _enabledTypes = {};
  bool _isLoading = true;

  // Define the list of types we care about (matching DataSource tiers)
  final List<HealthDataType> _displayTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.WATER,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.NUTRITION,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs.getAllPreferences(_displayTypes);
    if (mounted) {
      setState(() {
        _enabledTypes = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleType(HealthDataType type, bool value) async {
    await _prefs.setTypeEnabled(type, value);
    setState(() {
      _enabledTypes[type] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Health Data Settings',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _displayTypes.length,
              itemBuilder: (context, index) {
                final type = _displayTypes[index];
                final enabled = _enabledTypes[type] ?? true;
                return SwitchListTile(
                  title: Text(
                    _formatTypeName(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    enabled ? 'Syncing enabled' : 'Syncing disabled',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: enabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) => _toggleType(type, val),
                );
              },
            ),
    );
  }

  String _formatTypeName(HealthDataType type) {
    return type.name
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
