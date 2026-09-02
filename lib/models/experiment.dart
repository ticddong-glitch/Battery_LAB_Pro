import 'battery_material.dart';
import 'current_collector.dart';
import 'experiment_settings.dart';
import 'electrode.dart';
import 'shared_values.dart';
import 'solvent.dart';

class Experiment {
  /// Unique ID
  final String id;

  /// Experiment Name
  String name;

  /// Created Date
  DateTime createdAt;

  /// Last Modified Date
  DateTime updatedAt;

  /// Active / Completed / Archived
  ExperimentStatus status;

  /// Protocol Information
  String? protocolId;
  String? protocolName;
  String? protocolVersion;

  /// Experiment Settings (Snapshot)
  ExperimentSettings settings;

  /// Shared values (geometry/material/composition) - new model
  SharedValues sharedValues;

  /// Electrode List
  List<Electrode> electrodes;

  /// Optional Memo
  String memo;

  Experiment({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.settings,
    required this.sharedValues,
    this.protocolId,
    this.protocolName,
    this.protocolVersion,

    List<Electrode>? electrodes,

    this.memo = '',
  }) : electrodes = electrodes ?? <Electrode>[];

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'status': status.index,
      'protocolId': protocolId,
      'protocolName': protocolName,
      'protocolVersion': protocolVersion,
      // Keep compatibility keys for previously stored snapshots.
      'materialPresetId': sharedValues.materialPresetId,
      'collectorPresetId': sharedValues.collectorPresetId,
      'settings': settings.toMap(),
      'sharedValues': sharedValues.toMap(),
      'memo': memo,
      'electrodes': electrodes.map((e) => e.toMap()).toList(),
    };
  }

  static Experiment fromMap(Map<String, Object?> m) {
    final settings = (() {
      try {
        final settingsMap = (m['settings'] as Map).cast<String, Object?>();
        return ExperimentSettings.fromMap(settingsMap);
      } catch (_) {
        return ExperimentSettings(
          material: const BatteryMaterial(
            name: 'Unknown Material',
            theoreticalCapacity: 300,
            density: 1.55,
          ),
          collector: const CurrentCollector(
            name: 'Cu Foil',
            density: 8.96,
            thickness: 10,
            purity: 99.9,
          ),
          solvent: const Solvent(
            name: 'NMP',
            density: 1.03,
            boilingPoint: 202,
            dielectricConstant: 32,
          ),
          activeMaterial: 90,
          conductiveMaterial: 5,
          binder: 5,
          electrodeDiameter: 14,
          foilThickness: 10,
          averageFoilWeight: 0,
          specificCapacity: 300,
          trueDensity: 1.55,
          dryingTemperature: 120,
          dryingTime: 12,
          rollPressPressure: 50,
        );
      }
    })();

    final statusIndexRaw = (m['status'] as int?) ?? 0;
    final statusIndex = (statusIndexRaw >= 0 && statusIndexRaw < ExperimentStatus.values.length)
        ? statusIndexRaw
        : 0;

    final sharedValues = (() {
      try {
        if (m.containsKey('sharedValues') && m['sharedValues'] is Map) {
          final shared = SharedValues.fromMap((m['sharedValues'] as Map).cast<String, Object?>());
          shared.materialPresetId ??= m['materialPresetId'] as String?;
          shared.collectorPresetId ??= m['collectorPresetId'] as String?;
          return shared;
        }
      } catch (_) {
        // Fallback below.
      }
      return SharedValues(
        materialPresetId: m['materialPresetId'] as String?,
        collectorPresetId: m['collectorPresetId'] as String?,
        collectorPreset: settings.collector.name,
        activeMaterial: settings.material.name,
        electrodeDiameter: settings.electrodeDiameter,
        foilThickness: settings.foilThickness,
        collector: settings.collector,
        averageFoilWeight: settings.averageFoilWeight,
        trueDensity: settings.trueDensity,
        specificCapacity: settings.specificCapacity,
        activeMaterialRatio: settings.activeMaterial,
        conductiveAdditiveRatio: settings.conductiveMaterial,
        binderRatio: settings.binder,
        pressEnabled: false,
        targetPorosity: 0,
      );
    })();

    return Experiment(
      id: m['id'] as String,
      name: m['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      status: ExperimentStatus.values[statusIndex],
      settings: settings,
      sharedValues: sharedValues,
      electrodes: (m['electrodes'] as List?)?.map((e) => Electrode.fromMap((e as Map).cast<String, Object?>())).toList() ?? [],
      protocolId: m['protocolId'] as String?,
      protocolName: m['protocolName'] as String?,
      protocolVersion: m['protocolVersion'] as String?,
      memo: m['memo'] as String? ?? '',
    );
  }
}

enum ExperimentStatus {
  active,
  completed,
  archived,
}