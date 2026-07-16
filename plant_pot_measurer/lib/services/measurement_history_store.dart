import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_session.dart';
import '../models/pot_shape.dart';
import '../models/saved_measurement.dart';

/// Persists a history of completed measurements (dimensions, shape, and a
/// copy of the photo) to on-device storage so the user can look back at
/// pots they've measured before.
class MeasurementHistoryStore {
  const MeasurementHistoryStore._();

  static const _prefsKey = 'measurement_history_v1';

  /// Only the most recent entries are kept; older ones (and their photo
  /// copies) are pruned automatically.
  static const _maxEntries = 30;

  /// Loads saved measurements, newest first.
  static Future<List<SavedMeasurement>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded.map((entry) {
      final map = entry as Map<String, dynamic>;
      return SavedMeasurement(
        id: map['id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        photoPath: map['photoPath'] as String?,
        topDiameterCm: (map['topDiameterCm'] as num).toDouble(),
        bottomDiameterCm: (map['bottomDiameterCm'] as num).toDouble(),
        heightCm: (map['heightCm'] as num).toDouble(),
        shape: PotShape.values.byName(map['shape'] as String),
        referenceObjectName: map['referenceObjectName'] as String,
      );
    }).toList();

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static Future<void> _persist(List<SavedMeasurement> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      items
          .map(
            (m) => {
              'id': m.id,
              'timestamp': m.timestamp.toIso8601String(),
              'photoPath': m.photoPath,
              'topDiameterCm': m.topDiameterCm,
              'bottomDiameterCm': m.bottomDiameterCm,
              'heightCm': m.heightCm,
              'shape': m.shape.name,
              'referenceObjectName': m.referenceObjectName,
            },
          )
          .toList(),
    );
    await prefs.setString(_prefsKey, raw);
  }

  /// Saves a completed measurement session to history, copying its photo
  /// into permanent app storage first (image_picker's file may live in a
  /// cache directory that the OS can clear at any time).
  static Future<SavedMeasurement> add(MeasurementSession session) async {
    final topD = session.topDiameterCm;
    final bottomD = session.bottomDiameterCm;
    final h = session.heightCm;
    if (topD == null || bottomD == null || h == null) {
      throw StateError('Cannot save an incomplete measurement to history.');
    }

    final savedPhotoPath = await _copyPhoto(session.photo?.path);

    final entry = SavedMeasurement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      photoPath: savedPhotoPath,
      topDiameterCm: topD,
      bottomDiameterCm: bottomD,
      heightCm: h,
      shape: session.shape,
      referenceObjectName: session.referenceObject.name,
    );

    final items = await load();
    items.insert(0, entry);
    while (items.length > _maxEntries) {
      final removed = items.removeLast();
      await _deletePhotoFile(removed.photoPath);
    }
    await _persist(items);
    return entry;
  }

  /// Removes a single history entry (and its photo copy, if any).
  static Future<void> remove(String id) async {
    final items = await load();
    final index = items.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final removed = items.removeAt(index);
    await _deletePhotoFile(removed.photoPath);
    await _persist(items);
  }

  static Future<String?> _copyPhoto(String? sourcePath) async {
    if (sourcePath == null) return null;
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${docsDir.path}/measurement_photos');
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }

      final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      final destPath =
          '${historyDir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
      final copied = await sourceFile.copy(destPath);
      return copied.path;
    } catch (_) {
      // A missing photo is non-fatal — the history entry is still saved
      // with its dimensions and volume, just without a thumbnail.
      return null;
    }
  }

  static Future<void> _deletePhotoFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore — a stray file left behind isn't worth surfacing an error.
    }
  }
}
