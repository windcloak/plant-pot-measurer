import 'pot_shape.dart';
import '../utils/volume_calculator.dart';

/// A completed measurement kept in history so the user can look back at
/// past pots. Stores the raw dimensions and shape rather than a computed
/// volume, so volume is always derived with the current formulas.
class SavedMeasurement {
  final String id;
  final DateTime timestamp;

  /// Path to a copy of the photo kept in app storage, or null if the
  /// photo couldn't be saved (history entry is still kept either way).
  final String? photoPath;

  final double topDiameterCm;
  final double bottomDiameterCm;
  final double heightCm;
  final PotShape shape;
  final String referenceObjectName;

  const SavedMeasurement({
    required this.id,
    required this.timestamp,
    required this.photoPath,
    required this.topDiameterCm,
    required this.bottomDiameterCm,
    required this.heightCm,
    required this.shape,
    required this.referenceObjectName,
  });

  double get volumeCm3 => VolumeCalculator.volumeCm3(
    shape: shape,
    topDiameterCm: topDiameterCm,
    bottomDiameterCm: bottomDiameterCm,
    heightCm: heightCm,
  );
}
