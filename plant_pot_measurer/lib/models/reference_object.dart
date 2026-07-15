/// A real-world object of known size that the user places next to the pot
/// in the photo, so the app can convert pixel distances to centimeters.
class ReferenceObject {
  final String name;
  final double lengthCm;

  /// True if this came from the user's saved custom reference list
  /// (persisted via CustomReferenceStore), as opposed to a built-in
  /// preset or a one-off custom entry.
  final bool isUserSaved;

  /// Unique id for saved references, used to look them up for deletion.
  /// Null for built-in presets and one-off (unsaved) custom entries.
  final String? id;

  const ReferenceObject({
    required this.name,
    required this.lengthCm,
    this.isUserSaved = false,
    this.id,
  });

  /// True for the "enter your own length" sentinel option.
  bool get isCustom => lengthCm <= 0;

  static const custom = ReferenceObject(name: 'Custom / other', lengthCm: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceObject &&
          other.name == name &&
          other.lengthCm == lengthCm &&
          other.isUserSaved == isUserSaved &&
          other.id == id);

  @override
  int get hashCode => Object.hash(name, lengthCm, isUserSaved, id);

  /// Common household items with well-known, consistent dimensions.
  /// These are the "long edge" unless noted, since a long edge gives more
  /// pixels to measure against and therefore a more accurate calibration.
  static const presets = <ReferenceObject>[
    ReferenceObject(name: 'Credit / ID card (long edge)', lengthCm: 8.56),
    ReferenceObject(name: 'US quarter (diameter)', lengthCm: 2.426),
    ReferenceObject(name: 'US penny (diameter)', lengthCm: 1.905),
    ReferenceObject(name: 'A4 paper (long edge)', lengthCm: 29.7),
    ReferenceObject(name: 'US Letter paper (long edge)', lengthCm: 27.94),
    ReferenceObject(name: 'Standard ruler (30 cm)', lengthCm: 30),
    custom,
  ];
}
