import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reference_object.dart';

/// Persists the user's own reference objects (e.g. "My hand span = 18 cm")
/// to on-device storage so they can be reused for future pots without
/// retyping the length every time.
class CustomReferenceStore {
  const CustomReferenceStore._();

  static const _prefsKey = 'custom_reference_objects_v1';

  /// Loads all saved reference objects, in the order they were added.
  static Future<List<ReferenceObject>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) {
          final map = entry as Map<String, dynamic>;
          return ReferenceObject(
            id: map['id'] as String,
            name: map['name'] as String,
            lengthCm: (map['lengthCm'] as num).toDouble(),
            isUserSaved: true,
          );
        })
        .toList();
  }

  static Future<void> _persist(List<ReferenceObject> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'lengthCm': item.lengthCm,
            },
          )
          .toList(),
    );
    await prefs.setString(_prefsKey, raw);
  }

  /// Saves a new reference object and returns it.
  static Future<ReferenceObject> add({
    required String name,
    required double lengthCm,
  }) async {
    final items = await load();
    final newItem = ReferenceObject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      lengthCm: lengthCm,
      isUserSaved: true,
    );
    items.add(newItem);
    await _persist(items);
    return newItem;
  }

  /// Removes a saved reference object by id.
  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((item) => item.id == id);
    await _persist(items);
  }
}
