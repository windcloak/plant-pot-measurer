import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_unit.dart';

/// Persists the user's preferred display/input unit (cm or inches).
class UnitPreferenceStore {
  const UnitPreferenceStore._();

  static const _prefsKey = 'measurement_unit_v1';
  static const defaultUnit = MeasurementUnit.inches;

  static Future<MeasurementUnit> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return defaultUnit;
    return MeasurementUnit.values.firstWhere(
      (unit) => unit.name == raw,
      orElse: () => defaultUnit,
    );
  }

  static Future<void> save(MeasurementUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, unit.name);
  }
}
