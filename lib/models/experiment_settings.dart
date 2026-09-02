import 'battery_material.dart';
import 'current_collector.dart';
import 'solvent.dart';

class ExperimentSettings {
  /// Material
  BatteryMaterial material;

  /// Current Collector
  CurrentCollector collector;

  /// Solvent
  Solvent solvent;

  /// Composition (wt%)
  double activeMaterial;

  double conductiveMaterial;

  double binder;

  /// Electrode Diameter (mm)
  double electrodeDiameter;

  /// Shared foil thickness (μm)
  double foilThickness;

  /// Shared average foil weight (mg)
  double averageFoilWeight;

  /// Shared specific capacity (mAh/g)
  double specificCapacity;

  /// Shared true density (g/cm³)
  double trueDensity;

  /// Drying Temperature (°C)
  double dryingTemperature;

  /// Drying Time (hour)
  double dryingTime;

  /// Roll Press Pressure (MPa)
  double rollPressPressure;

  ExperimentSettings({
    required this.material,
    required this.collector,
    required this.solvent,

    required this.activeMaterial,
    required this.conductiveMaterial,
    required this.binder,

    required this.electrodeDiameter,
    this.foilThickness = 10,
    this.averageFoilWeight = 0,
    this.specificCapacity = 300,
    this.trueDensity = 1.55,

    required this.dryingTemperature,
    required this.dryingTime,

    required this.rollPressPressure,
  });

  Map<String, Object?> toMap() {
    return {
      'material': {
        'name': material.name,
        'theoreticalCapacity': material.theoreticalCapacity,
        'density': material.density,
      },
      'collector': {
        'name': collector.name,
        'density': collector.density,
        'thickness': collector.thickness,
        'purity': collector.purity,
      },
      'solvent': {
        'name': solvent.name,
        'density': solvent.density,
        'boilingPoint': solvent.boilingPoint,
        'dielectricConstant': solvent.dielectricConstant,
      },
      'activeMaterial': activeMaterial,
      'conductiveMaterial': conductiveMaterial,
      'binder': binder,
      'electrodeDiameter': electrodeDiameter,
      'foilThickness': foilThickness,
      'averageFoilWeight': averageFoilWeight,
      'specificCapacity': specificCapacity,
      'trueDensity': trueDensity,
      'dryingTemperature': dryingTemperature,
      'dryingTime': dryingTime,
      'rollPressPressure': rollPressPressure,
    };
  }

  static ExperimentSettings fromMap(Map<String, Object?> m) {
    final mat = m['material'] as Map<String, Object?>;
    final col = m['collector'] as Map<String, Object?>;
    final sol = m['solvent'] as Map<String, Object?>;

    return ExperimentSettings(
      material: BatteryMaterial(
        name: mat['name'] as String,
        theoreticalCapacity: (mat['theoreticalCapacity'] as num).toDouble(),
        density: (mat['density'] as num).toDouble(),
      ),
      collector: CurrentCollector(
        name: col['name'] as String,
        density: (col['density'] as num).toDouble(),
        thickness: (col['thickness'] as num).toDouble(),
        purity: (col['purity'] as num).toDouble(),
      ),
      solvent: Solvent(
        name: sol['name'] as String,
        density: (sol['density'] as num).toDouble(),
        boilingPoint: (sol['boilingPoint'] as num).toDouble(),
        dielectricConstant: (sol['dielectricConstant'] as num).toDouble(),
      ),
      activeMaterial: (m['activeMaterial'] as num).toDouble(),
      conductiveMaterial: (m['conductiveMaterial'] as num).toDouble(),
      binder: (m['binder'] as num).toDouble(),
      electrodeDiameter: (m['electrodeDiameter'] as num).toDouble(),
      foilThickness: (m['foilThickness'] as num).toDouble(),
      averageFoilWeight: (m['averageFoilWeight'] as num).toDouble(),
      specificCapacity: (m['specificCapacity'] as num).toDouble(),
      trueDensity: (m['trueDensity'] as num).toDouble(),
      dryingTemperature: (m['dryingTemperature'] as num).toDouble(),
      dryingTime: (m['dryingTime'] as num).toDouble(),
      rollPressPressure: (m['rollPressPressure'] as num).toDouble(),
    );
  }
}