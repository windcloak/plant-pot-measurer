import 'package:shared_preferences/shared_preferences.dart';

import '../models/reference_object.dart';

/// Remembers which reference object the user picked most recently, so the
/// next measurement can default to it instead of always starting blank.
///
/// Only built-in presets and saved custom references are remembered —
/// those have a stable identity (a name or an id) that can be resolved
/// again later. A one-off "Custom / other" entry that the user chose not
/// to save has nothing stable to point back to, so it's simply not
/// remembered (the previous remembered choice, if any, is left as-is).
class LastReferenceStore {
  const LastReferenceStore._();

  static const _prefsKey = 'last_reference_object_v1';
  static const _presetPrefix = 'preset:';
  static const _savedPrefix = 'saved:';

  /// Records [ref] as the most recently used reference object. No-op for
  /// one-off custom references (see class doc).
  static Future<void> save(ReferenceObject ref) async {
    final prefs = await SharedPreferences.getInstance();
    if (ref.isUserSaved && ref.id != null) {
      await prefs.setString(_prefsKey, '$_savedPrefix${ref.id}');
    } else if (ReferenceObject.presets.contains(ref)) {
      await prefs.setString(_prefsKey, '$_presetPrefix${ref.name}');
    }
    // Otherwise: a one-off custom reference — nothing stable to remember.
  }

  /// Resolves the last-used reference against the currently available
  /// presets and [savedReferences]. Returns null if nothing was
  /// remembered, or the remembered one no longer exists (e.g. it was
  /// since deleted from the saved list).
  static Future<ReferenceObject?> load(
    List<ReferenceObject> savedReferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;

    if (raw.startsWith(_presetPrefix)) {
      final name = raw.substring(_presetPrefix.length);
      for (final preset in ReferenceObject.presets) {
        if (!preset.isCustom && preset.name == name) return preset;
      }
      return null;
    }

    if (raw.startsWith(_savedPrefix)) {
      final id = raw.substring(_savedPrefix.length);
      for (final ref in savedReferences) {
        if (ref.id == id) return ref;
      }
      return null;
    }

    return null;
  }
}
