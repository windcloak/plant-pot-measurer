import 'dart:io';
import 'dart:ui';

import 'pot_shape.dart';
import 'reference_object.dart';

/// Two tapped points marking the ends of one measurement (e.g. the two
/// edges of the top rim, in image pixel coordinates).
class PointPair {
  Offset? start;
  Offset? end;

  bool get isComplete => start != null && end != null;

  double get pixelDistance {
    if (!isComplete) return 0;
    return (end! - start!).distance;
  }
}

/// Holds all the state for one measuring session: the photo, the
/// calibration reference, the three tapped measurements, and the chosen
/// pot shape. Also computes the derived real-world values.
class MeasurementSession {
  File? photo;

  /// Always a concrete reference (name + positive lengthCm) by the time
  /// calibration happens — [CaptureScreen] resolves the "Custom / other"
  /// sentinel into a real object (saved or one-off) before this is set.
  ReferenceObject referenceObject = ReferenceObject.presets.first;

  final PointPair calibration = PointPair();
  final PointPair topDiameter = PointPair();
  final PointPair bottomDiameter = PointPair();
  final PointPair height = PointPair();

  PotShape shape = PotShape.frustum;

  /// centimeters represented by one pixel in the source photo.
  double? get cmPerPixel {
    if (!calibration.isComplete || referenceObject.lengthCm <= 0) return null;
    final pixels = calibration.pixelDistance;
    if (pixels <= 0) return null;
    return referenceObject.lengthCm / pixels;
  }

  double? _cm(PointPair pair) {
    final ratio = cmPerPixel;
    if (ratio == null || !pair.isComplete) return null;
    return pair.pixelDistance * ratio;
  }

  double? get topDiameterCm => _cm(topDiameter);
  double? get bottomDiameterCm => _cm(bottomDiameter);
  double? get heightCm => _cm(height);

  bool get isReadyForResults =>
      topDiameterCm != null && bottomDiameterCm != null && heightCm != null;
}
