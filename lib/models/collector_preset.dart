import 'dart:convert';

class CollectorPreset {
  final String id;
  final String presetName;
  final String collectorMaterial;
  final double thickness;
  final double punchDiameter;
  final double averageFoilWeight;
  final String memo;

  const CollectorPreset({
    required this.id,
    required this.presetName,
    required this.collectorMaterial,
    required this.thickness,
    double? density,
    required this.punchDiameter,
    required this.averageFoilWeight,
    this.memo = '',
    bool? isCustom,
  });

  CollectorPreset copyWith({
    String? id,
    String? presetName,
    String? collectorMaterial,
    double? thickness,
    double? density,
    double? punchDiameter,
    double? averageFoilWeight,
    String? memo,
    bool? isCustom,
  }) {
    return CollectorPreset(
      id: id ?? this.id,
      presetName: presetName ?? this.presetName,
      collectorMaterial: collectorMaterial ?? this.collectorMaterial,
      thickness: thickness ?? this.thickness,
      punchDiameter: punchDiameter ?? this.punchDiameter,
      averageFoilWeight: averageFoilWeight ?? this.averageFoilWeight,
      memo: memo ?? this.memo,
    );
  }

  // Legacy compatibility for code paths from prior sprints.
  double get density => 0;

  // Legacy compatibility for code paths from prior sprints.
  bool get isCustom => true;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'presetName': presetName,
      'collectorMaterial': collectorMaterial,
      'thickness': thickness,
      'punchDiameter': punchDiameter,
      'averageFoilWeight': averageFoilWeight,
      'memo': memo,
    };
  }

  String toJson() => jsonEncode(toMap());

  static CollectorPreset fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return fromMap(map);
  }

  static CollectorPreset fromMap(Map<String, Object?> map) {
    return CollectorPreset(
      id: (map['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      presetName: (map['presetName'] as String?) ?? 'Unnamed Collector',
      collectorMaterial: (map['collectorMaterial'] as String?) ?? '',
      thickness: (map['thickness'] as num?)?.toDouble() ?? 0,
      punchDiameter: (map['punchDiameter'] as num?)?.toDouble() ?? 0,
      averageFoilWeight: (map['averageFoilWeight'] as num?)?.toDouble() ?? 0,
      memo: (map['memo'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectorPreset &&
        other.id == id &&
        other.presetName == presetName &&
        other.collectorMaterial == collectorMaterial &&
        other.thickness == thickness &&
        other.punchDiameter == punchDiameter &&
        other.averageFoilWeight == averageFoilWeight &&
        other.memo == memo;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      presetName,
      collectorMaterial,
      thickness,
      punchDiameter,
      averageFoilWeight,
      memo,
    );
  }
}
