import 'dart:math' as math;

import '../models/pot_shape.dart';

/// Volume math for approximating a plant pot's capacity from its top
/// diameter, bottom diameter, and height (all in centimeters).
///
/// All pot shapes are simplified to bodies of revolution. This is an
/// estimate for gardening purposes (choosing potting soil quantity, sizing
/// up a pot, etc.), not a precision measurement.
class VolumeCalculator {
  const VolumeCalculator._();

  /// Volume in cubic centimeters for the given [shape].
  static double volumeCm3({
    required PotShape shape,
    required double topDiameterCm,
    required double bottomDiameterCm,
    required double heightCm,
  }) {
    switch (shape) {
      case PotShape.cylinder:
        return _cylinder(topDiameterCm, bottomDiameterCm, heightCm);
      case PotShape.frustum:
        return _frustum(topDiameterCm, bottomDiameterCm, heightCm);
      case PotShape.taperedRoundedBottom:
        // A rounded bottom corner removes a bit of the sharp-cornered
        // frustum's interior volume near the base. There's no separate
        // tap point for the rounding radius, so we apply a fixed empirical
        // correction (~5%) rather than pretend to precision we don't have.
        // This is intentionally conservative and called out as an estimate
        // in the results screen.
        return _frustum(topDiameterCm, bottomDiameterCm, heightCm) * 0.95;
    }
  }

  static double _cylinder(double topD, double bottomD, double h) {
    final avgRadius = (topD + bottomD) / 4;
    return math.pi * avgRadius * avgRadius * h;
  }

  static double _frustum(double topD, double bottomD, double h) {
    final r1 = topD / 2;
    final r2 = bottomD / 2;
    return (math.pi * h / 3) * (r1 * r1 + r1 * r2 + r2 * r2);
  }

  static double cm3ToLiters(double cm3) => cm3 / 1000;
  static double cm3ToUsGallons(double cm3) => cm3 / 3785.41;
  static double cm3ToUsQuarts(double cm3) => cm3 / 946.353;
  static double cm3ToUsCups(double cm3) => cm3 / 236.588;
}
