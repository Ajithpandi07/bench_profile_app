import 'package:health/health.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../features/sleep/domain/entities/ignored_sleep_draft.dart';

class HealthPreferencesService {
  final Isar? isar;

  HealthPreferencesService({this.isar});

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

  Future<void> ignoreSleepUuid(String uuid) async {
    if (isar == null) return;

    final draft = IgnoredSleepDraft()
      ..uuid = uuid
      ..ignoredAt = DateTime.now();

    await isar!.writeTxn(() async {
      await isar!.ignoredSleepDrafts.putByIndex('uuid', draft);
    });
  }

  Future<bool> isSleepUuidIgnored(String uuid) async {
    if (isar == null) return false;

    final count = await isar!.ignoredSleepDrafts
        .where()
        .uuidEqualTo(uuid)
        .count();
    return count > 0;
  }
}
