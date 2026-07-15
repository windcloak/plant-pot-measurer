/// A real-world object of known size that the user places next to the pot
/// in the photo, so the app can convert pixel distances to centimeters.
class ReferenceObject {
  final String name;
  final double lengthCm;

  const ReferenceObject({required this.name, required this.lengthCm});

  /// True for the "enter your own length" option.
  bool get isCustom => lengthCm <= 0;

  static const custom = ReferenceObject(name: 'Custom / other', lengthCm: 0);

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
