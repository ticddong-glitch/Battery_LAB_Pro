class Protocol {
  final String id;
  String name;

  // Metadata
  String version;
  DateTime createdAt;
  DateTime updatedAt;

  // Material
  String? materialPresetId;
  String materialName;
  double specificCapacity; // mAh/g
  double trueDensity; // g/cm3

  // Current collector
  String? collectorPresetId;
  String collectorName;
  double collectorThickness; // μm
  double collectorDensity; // g/cm3
  double averageFoilWeight; // mg

  // Geometry
  double diameter; // mm

  // Composition
  double activeRatio; // %
  double conductiveRatio; // %
  double binderRatio; // %

  // Target / misc
  double targetPorosity; // %
  double solidContent; // fraction 0-1

  // Process defaults
  double dryingTemperature; // C
  double dryingTime; // hour
  double rollPressPressure; // MPa

  // Notes
  String notes;

  Protocol({
    required this.id,
    required this.name,
    this.version = 'v1.0',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.materialPresetId,
    required this.materialName,
    required this.specificCapacity,
    required this.trueDensity,
    this.collectorPresetId,
    required this.collectorName,
    required this.collectorThickness,
    required this.collectorDensity,
    required this.averageFoilWeight,
    required this.diameter,
    required this.activeRatio,
    required this.conductiveRatio,
    required this.binderRatio,
    required this.targetPorosity,
    required this.solidContent,
    this.dryingTemperature = 120,
    this.dryingTime = 12,
    this.rollPressPressure = 50,
    this.notes = '',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Protocol copyWith({
    String? id,
    String? name,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? materialPresetId,
    String? materialName,
    double? specificCapacity,
    double? trueDensity,
    String? collectorPresetId,
    String? collectorName,
    double? collectorThickness,
    double? collectorDensity,
    double? averageFoilWeight,
    double? diameter,
    double? activeRatio,
    double? conductiveRatio,
    double? binderRatio,
    double? targetPorosity,
    double? solidContent,
    double? dryingTemperature,
    double? dryingTime,
    double? rollPressPressure,
    String? notes,
    bool clearMaterialPresetId = false,
    bool clearCollectorPresetId = false,
  }) {
    return Protocol(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      materialPresetId: clearMaterialPresetId ? null : (materialPresetId ?? this.materialPresetId),
      materialName: materialName ?? this.materialName,
      specificCapacity: specificCapacity ?? this.specificCapacity,
      trueDensity: trueDensity ?? this.trueDensity,
      collectorPresetId: clearCollectorPresetId ? null : (collectorPresetId ?? this.collectorPresetId),
      collectorName: collectorName ?? this.collectorName,
      collectorThickness: collectorThickness ?? this.collectorThickness,
      collectorDensity: collectorDensity ?? this.collectorDensity,
      averageFoilWeight: averageFoilWeight ?? this.averageFoilWeight,
      diameter: diameter ?? this.diameter,
      activeRatio: activeRatio ?? this.activeRatio,
      conductiveRatio: conductiveRatio ?? this.conductiveRatio,
      binderRatio: binderRatio ?? this.binderRatio,
      targetPorosity: targetPorosity ?? this.targetPorosity,
      solidContent: solidContent ?? this.solidContent,
      dryingTemperature: dryingTemperature ?? this.dryingTemperature,
      dryingTime: dryingTime ?? this.dryingTime,
      rollPressPressure: rollPressPressure ?? this.rollPressPressure,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'materialPresetId': materialPresetId,
      'materialName': materialName,
      'specificCapacity': specificCapacity,
      'trueDensity': trueDensity,
      'collectorPresetId': collectorPresetId,
      'collectorName': collectorName,
      'collectorThickness': collectorThickness,
      'collectorDensity': collectorDensity,
      'averageFoilWeight': averageFoilWeight,
      'diameter': diameter,
      'activeRatio': activeRatio,
      'conductiveRatio': conductiveRatio,
      'binderRatio': binderRatio,
      'targetPorosity': targetPorosity,
      'solidContent': solidContent,
      'dryingTemperature': dryingTemperature,
      'dryingTime': dryingTime,
      'rollPressPressure': rollPressPressure,
      'notes': notes,
    };
  }

  static Protocol fromMap(Map<String, Object?> m) {
    return Protocol(
      id: m['id'] as String,
      name: m['name'] as String,
      version: m['version'] as String? ?? 'v1.0',
      createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      materialPresetId: m['materialPresetId'] as String?,
      materialName: m['materialName'] as String,
      specificCapacity: (m['specificCapacity'] as num).toDouble(),
      trueDensity: (m['trueDensity'] as num).toDouble(),
      collectorPresetId: m['collectorPresetId'] as String?,
      collectorName: m['collectorName'] as String,
      collectorThickness: (m['collectorThickness'] as num).toDouble(),
      collectorDensity: (m['collectorDensity'] as num?)?.toDouble() ?? 8.96,
      averageFoilWeight: (m['averageFoilWeight'] as num).toDouble(),
      diameter: (m['diameter'] as num).toDouble(),
      activeRatio: (m['activeRatio'] as num).toDouble(),
      conductiveRatio: (m['conductiveRatio'] as num).toDouble(),
      binderRatio: (m['binderRatio'] as num).toDouble(),
      targetPorosity: (m['targetPorosity'] as num).toDouble(),
      solidContent: (m['solidContent'] as num).toDouble(),
      dryingTemperature: (m['dryingTemperature'] as num?)?.toDouble() ?? 120,
      dryingTime: (m['dryingTime'] as num?)?.toDouble() ?? 12,
      rollPressPressure: (m['rollPressPressure'] as num?)?.toDouble() ?? 50,
      notes: m['notes'] as String? ?? '',
    );
  }
}
