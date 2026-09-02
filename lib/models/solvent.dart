class Solvent {
  /// Ex) NMP, DMF
  final String name;

  /// g/cm³
  final double density;

  /// °C
  final double boilingPoint;

  /// Relative dielectric constant
  final double dielectricConstant;

  const Solvent({
    required this.name,
    required this.density,
    required this.boilingPoint,
    required this.dielectricConstant,
  });
}