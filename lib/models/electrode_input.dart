class ElectrodeInput {
  /// Total Electrode Mass (mg)
  double totalMass;

  /// Current Collector Mass (mg)
  double collectorMass;

  /// Electrode Diameter (mm)
  double diameter;

  /// Electrode Thickness (μm)
  double thickness;

  /// Optional Memo
  String memo;

  ElectrodeInput({
    this.totalMass = 0,
    this.collectorMass = 0,
    this.diameter = 14.0,
    this.thickness = 0,
    this.memo = '',
  });

  Map<String, Object?> toMap() {
    return {
      'totalMass': totalMass,
      'collectorMass': collectorMass,
      'diameter': diameter,
      'thickness': thickness,
      'memo': memo,
    };
  }

  static ElectrodeInput fromMap(Map<String, Object?> m) {
    return ElectrodeInput(
      totalMass: (m['totalMass'] as num?)?.toDouble() ?? 0,
      collectorMass: (m['collectorMass'] as num?)?.toDouble() ?? 0,
      diameter: (m['diameter'] as num?)?.toDouble() ?? 14.0,
      thickness: (m['thickness'] as num?)?.toDouble() ?? 0,
      memo: m['memo'] as String? ?? '',
    );
  }
}