class BatteryMaterial {
  final String name;

  /// mAh/g
  final double theoreticalCapacity;

  /// g/cm3
  final double density;

  /// Optional Memo
  final String? description;

  const BatteryMaterial({
    required this.name,
    required this.theoreticalCapacity,
    required this.density,
    this.description,
  });
}