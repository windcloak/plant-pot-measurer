/// Converts a true (liquid) volume into the nursery industry's "trade
/// gallon" sizing scale.
///
/// Nursery/garden-center pot sizes like "#5" or "#7 gallon" are size-class
/// marketing labels, not real liquid gallons. A trade gallon is smaller
/// than a true gallon (128 fl oz / 3.785 L) and the gap changes at
/// different sizes — it traces back to nurseries originally growing
/// plants in surplus 1-gallon food cans after WWII, and the "gallon"
/// name never got corrected as container shapes evolved.
///
/// This converter interpolates against widely-cited industry reference
/// points so a pot you measure at home (its true volume) can be compared
/// to a nursery pot on the shelf — e.g. a true 5-gallon bucket lands
/// close to a nursery "#7 gallon" pot, not a "#5". These reference points
/// vary by manufacturer and aren't a single locked-down standard, so
/// treat the result as a size-class estimate, not a precise conversion.
class NurseryGallonConverter {
  const NurseryGallonConverter._();

  /// Reference points sorted by true-gallon capacity ascending: each is
  /// a (trade designation number, approximate true-gallon capacity) pair.
  static const List<({double designation, double trueGallons})>
  _referencePoints = [
    (designation: 0.25, trueGallons: 0.22), // quart / 4" pot
    (designation: 1, trueGallons: 0.745), // #1 "trade gallon"
    (designation: 2, trueGallons: 1.6), // #2
    (designation: 3, trueGallons: 2.5), // #3
    (designation: 5, trueGallons: 3.6), // #5
    (designation: 7, trueGallons: 6.5), // #7
    (designation: 10, trueGallons: 8.0), // #10
    (designation: 15, trueGallons: 15.0), // #15
    (designation: 25, trueGallons: 25.0), // #25
  ];

  /// Estimates the nursery trade-gallon size number for a true volume
  /// given in US liquid gallons, via piecewise-linear interpolation
  /// between the reference points (and linear extrapolation past either
  /// end of the table).
  static double tradeGallonsForTrueGallons(double trueGallons) {
    final points = _referencePoints;

    if (trueGallons <= points.first.trueGallons) {
      return _extrapolate(points[0], points[1], trueGallons);
    }
    if (trueGallons >= points.last.trueGallons) {
      return _extrapolate(
        points[points.length - 2],
        points[points.length - 1],
        trueGallons,
      );
    }

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (trueGallons >= a.trueGallons && trueGallons <= b.trueGallons) {
        final t =
            (trueGallons - a.trueGallons) / (b.trueGallons - a.trueGallons);
        return a.designation + t * (b.designation - a.designation);
      }
    }
    return trueGallons; // unreachable
  }

  static double _extrapolate(
    ({double designation, double trueGallons}) a,
    ({double designation, double trueGallons}) b,
    double trueGallons,
  ) {
    final slope =
        (b.designation - a.designation) / (b.trueGallons - a.trueGallons);
    final result = a.designation + slope * (trueGallons - a.trueGallons);
    return result < 0 ? 0 : result;
  }
}
