import 'current_collector.dart';

class SharedValues {
  static const String keyMaterialPresetId = 'materialPresetId';
  static const String keyCollectorPresetId = 'collectorPresetId';
  static const String keyMaterialName = 'activeMaterial';
  static const String keyCollectorName = 'collectorPreset';
  static const String keyActiveMaterialRatio = 'activeMaterialRatio';
  static const String keyConductiveAdditiveRatio = 'conductiveAdditiveRatio';
  static const String keyBinderRatio = 'binderRatio';
  static const String keyPunchDiameter = 'punchDiameter';
  static const String keyElectrodeDiameter = 'electrodeDiameter';
  static const String keyAverageFoilWeight = 'averageFoilWeight';
  static const String keyFoilThickness = 'foilThickness';
  static const String keySpecificCapacity = 'specificCapacity';
  static const String keyTrueDensity = 'trueDensity';
  static const String keyTargetPorosity = 'targetPorosity';
  static const String keyPressEnabled = 'pressEnabled';

  String? materialPresetId;
  String? collectorPresetId;

  // Shared references
  String collectorPreset;
  String activeMaterial;

  // Geometry
  double electrodeDiameter;
  double foilThickness;

  // Material
  CurrentCollector collector;
  double averageFoilWeight;
  double trueDensity;
  double specificCapacity;

  // Composition
  double activeMaterialRatio;
  double conductiveAdditiveRatio;
  double binderRatio;

  // Press defaults
  bool pressEnabled;
  double targetPorosity;

  SharedValues({
    this.materialPresetId,
    this.collectorPresetId,
    this.collectorPreset = '',
    this.activeMaterial = '',
    required this.electrodeDiameter,
    this.foilThickness = 10,
    required this.collector,
    this.averageFoilWeight = 0,
    this.trueDensity = 1.55,
    this.specificCapacity = 300,
    required this.activeMaterialRatio,
    required this.conductiveAdditiveRatio,
    required this.binderRatio,
    this.pressEnabled = false,
    this.targetPorosity = 0,
  });

  double get punchDiameter => electrodeDiameter;
  set punchDiameter(double value) => electrodeDiameter = value;

  double resolveNumericValue(String key) {
    switch (key) {
      case keyActiveMaterialRatio:
        return activeMaterialRatio;
      case keyConductiveAdditiveRatio:
        return conductiveAdditiveRatio;
      case keyBinderRatio:
        return binderRatio;
      case keyPunchDiameter:
      case keyElectrodeDiameter:
        return electrodeDiameter;
      case keyAverageFoilWeight:
        return averageFoilWeight;
      case keyFoilThickness:
        return foilThickness;
      case keySpecificCapacity:
        return specificCapacity;
      case keyTrueDensity:
        return trueDensity;
      case keyTargetPorosity:
        return targetPorosity;
      default:
        return 0;
    }
  }

  bool resolveBoolValue(String key) {
    if (key == keyPressEnabled) {
      return pressEnabled;
    }
    return false;
  }

  String? resolveStringValue(String key) {
    switch (key) {
      case keyMaterialPresetId:
        return materialPresetId;
      case keyCollectorPresetId:
        return collectorPresetId;
      case keyMaterialName:
        return activeMaterial;
      case keyCollectorName:
        return collectorPreset;
      default:
        return null;
    }
  }

  Map<String, Object?> toMap() {
    return {
      'collectorPreset': collectorPreset,
      'activeMaterial': activeMaterial,
      'materialPresetId': materialPresetId,
      'collectorPresetId': collectorPresetId,
      'electrodeDiameter': electrodeDiameter,
      'punchDiameter': electrodeDiameter,
      'foilThickness': foilThickness,
      'collector': {
        'name': collector.name,
        'density': collector.density,
        'thickness': collector.thickness,
        'purity': collector.purity,
      },
      'averageFoilWeight': averageFoilWeight,
      'trueDensity': trueDensity,
      'specificCapacity': specificCapacity,
      'activeMaterialRatio': activeMaterialRatio,
      'conductiveAdditiveRatio': conductiveAdditiveRatio,
      'binderRatio': binderRatio,
      'pressEnabled': pressEnabled,
      'targetPorosity': targetPorosity,
    };
  }

  static SharedValues fromMap(Map<String, Object?> m) {
    final col = (m['collector'] as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
    return SharedValues(
      materialPresetId: m['materialPresetId'] as String?,
      collectorPresetId: m['collectorPresetId'] as String?,
      collectorPreset: m['collectorPreset'] as String? ?? (col['name'] as String? ?? ''),
      activeMaterial: m['activeMaterial'] as String? ?? '',
      electrodeDiameter:
          (m['punchDiameter'] as num?)?.toDouble() ??
          (m['electrodeDiameter'] as num?)?.toDouble() ??
          14.0,
      foilThickness: (m['foilThickness'] as num?)?.toDouble() ?? 10.0,
      collector: CurrentCollector(
        name: col['name'] as String? ?? 'Cu Foil',
        density: (col['density'] as num?)?.toDouble() ?? 8.96,
        thickness: (col['thickness'] as num?)?.toDouble() ?? 10,
        purity: (col['purity'] as num?)?.toDouble() ?? 99.9,
      ),
      averageFoilWeight: (m['averageFoilWeight'] as num?)?.toDouble() ?? 0.0,
      trueDensity: (m['trueDensity'] as num?)?.toDouble() ?? 1.55,
      specificCapacity: (m['specificCapacity'] as num?)?.toDouble() ?? 300.0,
      activeMaterialRatio: (m['activeMaterialRatio'] as num?)?.toDouble() ?? 0.0,
      conductiveAdditiveRatio: (m['conductiveAdditiveRatio'] as num?)?.toDouble() ?? 0.0,
      binderRatio: (m['binderRatio'] as num?)?.toDouble() ?? 0.0,
      pressEnabled: m['pressEnabled'] as bool? ?? (((m['targetPorosity'] as num?)?.toDouble() ?? 0) > 0),
      targetPorosity: (m['targetPorosity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
