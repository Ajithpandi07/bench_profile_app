import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthPreferencesService {
  static const String _prefix = 'health_pref_';

  Future<bool> isTypeEnabled(HealthDataType type) async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set
    return prefs.getBool('$_prefix${type.name}') ?? true;
  }

  Future<void> setTypeEnabled(HealthDataType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${type.name}', enabled);
  }

  Future<Map<HealthDataType, bool>> getAllPreferences(
    List<HealthDataType> allTypes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<HealthDataType, bool> result = {};
    for (final type in allTypes) {
      result[type] = prefs.getBool('$_prefix${type.name}') ?? true;
    }
    return result;
  }
}
