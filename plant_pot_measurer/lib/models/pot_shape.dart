/// The set of simplified geometric shapes a plant pot can be approximated as.
///
/// Real pots vary a lot, so we only offer a few practical presets rather than
/// trying to auto-detect shape from the photo.
enum PotShape {
  /// Straight sides, top diameter ~= bottom diameter.
  cylinder,

  /// Classic tapered pot: wider at the top, narrower at the bottom
  /// (or vice versa). Modeled as a conical frustum.
  frustum,

  /// Tapered sides like [frustum], but with a rounded/curved transition
  /// into the base rather than a sharp corner (common on plastic nursery
  /// pots). Volume is estimated as the frustum volume minus a small
  /// correction for the rounded corner.
  taperedRoundedBottom,
}

extension PotShapeInfo on PotShape {
  String get label {
    switch (this) {
      case PotShape.cylinder:
        return 'Cylinder';
      case PotShape.frustum:
        return 'Tapered (frustum)';
      case PotShape.taperedRoundedBottom:
        return 'Tapered, rounded bottom';
    }
  }

  String get description {
    switch (this) {
      case PotShape.cylinder:
        return 'Straight sides, top and bottom are about the same width.';
      case PotShape.frustum:
        return 'Sides taper evenly from top to bottom, like most plant pots.';
      case PotShape.taperedRoundedBottom:
        return 'Tapered sides that curve into the base instead of a sharp '
            'corner. Common on plastic nursery pots. Volume is an estimate.';
    }
  }
}
