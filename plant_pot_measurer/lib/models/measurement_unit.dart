/// The unit used to display and enter lengths throughout the app.
///
/// All lengths are still stored internally in centimeters (that's what
/// every calculation in the app works in) — this only controls what unit
/// the user sees and types in. Use [fromCm] to convert a stored cm value
/// for display, and [toCm] to convert a value the user typed back to cm
/// for storage/calculation.
enum MeasurementUnit {
  centimeters,
  inches;

  static const double _cmPerInch = 2.54;

  String get abbreviation =>
      this == MeasurementUnit.centimeters ? 'cm' : 'in';

  String get label =>
      this == MeasurementUnit.centimeters ? 'Centimeters (cm)' : 'Inches (in)';

  /// The other unit — handy for showing a secondary conversion alongside
  /// the primary one.
  MeasurementUnit get other =>
      this == MeasurementUnit.centimeters
          ? MeasurementUnit.inches
          : MeasurementUnit.centimeters;

  /// Converts a value stored in centimeters into this unit.
  double fromCm(double cm) =>
      this == MeasurementUnit.centimeters ? cm : cm / _cmPerInch;

  /// Converts a value the user entered in this unit into centimeters.
  double toCm(double value) =>
      this == MeasurementUnit.centimeters ? value : value * _cmPerInch;
}
