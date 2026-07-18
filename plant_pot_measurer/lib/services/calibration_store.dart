import 'package:shared_preferences/shared_preferences.dart';

/// Persists a single multiplicative correction factor derived from the
/// user comparing the app's measurements against a real-world measurement
/// (e.g. with a ruler or tape measure).
///
/// A factor of 1.0 means "no correction" (the default). A factor of, say,
/// 1.05 means every future measurement's centimeter conversion is
/// multiplied by 1.05 — this corrects for a systematic bias (most likely
/// in the reference-object calibration step) rather than a one-off
/// mistake on a single pot.
class CalibrationStore {
  const CalibrationStore._();

  static const _prefsKey = 'measurement_calibration_factor_v1';
  static const defaultFactor = 1.0;

  /// Loads the current correction factor, or [defaultFactor] if none has
  /// been saved yet.
  static Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefsKey) ?? defaultFactor;
  }

  /// Saves a new correction factor for future measurements.
  static Future<void> save(double factor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, factor);
  }

  /// Clears any saved correction, returning future measurements to
  /// uncorrected (factor 1.0).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
