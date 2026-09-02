class CurrentCollector {
  /// Ex) Cu Foil, Al Foil
  final String name;

  /// g/cm³
  final double density;

  /// μm
  final double thickness;

  /// %
  final double purity;

  const CurrentCollector({
    required this.name,
    required this.density,
    required this.thickness,
    required this.purity,
  });

  CurrentCollector copyWith({
    String? name,
    double? density,
    double? thickness,
    double? purity,
  }) {
    return CurrentCollector(
      name: name ?? this.name,
      density: density ?? this.density,
      thickness: thickness ?? this.thickness,
      purity: purity ?? this.purity,
    );
  }
}