import '../models/battery_material.dart';
import '../models/current_collector.dart';
import '../models/electrode.dart';
import '../models/electrode_input.dart';
import '../models/calculation_result.dart';
import '../models/experiment.dart';
import '../models/experiment_settings.dart';
import '../models/protocol.dart';
import '../models/shared_values.dart';
import '../models/solvent.dart';

class ExperimentFactory {
  static Experiment create({
    required String name,
    required Protocol protocol,
    required int electrodeCount,
  }) {
    final material = BatteryMaterial(
      name: protocol.materialName,
      theoreticalCapacity: protocol.specificCapacity,
      density: protocol.trueDensity,
    );

    final collector = CurrentCollector(
      name: protocol.collectorName,
      density: protocol.collectorDensity,
      thickness: protocol.collectorThickness,
      purity: 99.9,
    );

    // Solvent is not part of Protocol model and is copied by value.
    const solvent = Solvent(
      name: "NMP",
      density: 1.03,
      boilingPoint: 202,
      dielectricConstant: 32.2,
    );

    // Experiment Settings
    final settings = ExperimentSettings(
      material: material,
      collector: collector,
      solvent: solvent,
      activeMaterial: protocol.activeRatio,
      conductiveMaterial: protocol.conductiveRatio,
      binder: protocol.binderRatio,
      electrodeDiameter: protocol.diameter,
      foilThickness: protocol.collectorThickness,
      averageFoilWeight: protocol.averageFoilWeight,
      specificCapacity: protocol.specificCapacity,
      trueDensity: protocol.trueDensity,
      dryingTemperature: protocol.dryingTemperature,
      dryingTime: protocol.dryingTime,
      rollPressPressure: protocol.rollPressPressure,
    );

    final sharedValues = SharedValues(
      materialPresetId: protocol.materialPresetId,
      collectorPresetId: protocol.collectorPresetId,
      collectorPreset: protocol.collectorName,
      activeMaterial: protocol.materialName,
      electrodeDiameter: settings.electrodeDiameter,
      foilThickness: settings.foilThickness,
      collector: CurrentCollector(
        name: settings.collector.name,
        density: settings.collector.density,
        thickness: settings.collector.thickness,
        purity: settings.collector.purity,
      ),
      averageFoilWeight: settings.averageFoilWeight,
      trueDensity: settings.trueDensity,
      specificCapacity: settings.specificCapacity,
      activeMaterialRatio: settings.activeMaterial,
      conductiveAdditiveRatio: settings.conductiveMaterial,
      binderRatio: settings.binder,
      pressEnabled: protocol.targetPorosity > 0,
      targetPorosity: protocol.targetPorosity,
    );

    // Electrode defaults are initialized from SharedValues and may be overridden later.
    final electrodes = List.generate(
      electrodeCount,
      (index) => Electrode(
        number: index + 1,
        input: ElectrodeInput(
          collectorMass: sharedValues.averageFoilWeight,
          diameter: sharedValues.electrodeDiameter,
          thickness: sharedValues.foilThickness,
        ),
        result: CalculationResult(),
      ),
    );

    return Experiment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ExperimentStatus.active,
      protocolId: protocol.id,
      protocolName: protocol.name,
      protocolVersion: protocol.version,
      settings: settings,
      sharedValues: sharedValues,
      electrodes: electrodes,
      memo: protocol.notes,
    );
  }
}