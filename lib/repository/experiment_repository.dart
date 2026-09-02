import 'dart:async';
import 'dart:convert';

import '../models/battery_material.dart';
import '../models/calculation_result.dart';
import '../models/current_collector.dart';
import '../models/electrode.dart';
import '../models/electrode_input.dart';
import '../models/experiment.dart';
import '../models/experiment_settings.dart';
import '../models/protocol.dart';
import '../models/shared_values.dart';
import '../models/solvent.dart';
import '../sevices/calculation_service.dart';
import 'db_helper.dart';
import 'protocol_repository.dart';

class _IntegrityRepairResult {
  final Experiment experiment;
  final bool repaired;

  const _IntegrityRepairResult({
    required this.experiment,
    required this.repaired,
  });
}

class ExperimentRepository {
  ExperimentRepository._();

  static final ExperimentRepository instance =
      ExperimentRepository._();

  final List<Experiment> _experiments = [];

  static const BatteryMaterial _defaultMaterial = BatteryMaterial(
    name: 'Unknown Material',
    theoreticalCapacity: 300,
    density: 1.55,
  );
  static const CurrentCollector _defaultCollector = CurrentCollector(
    name: 'Cu Foil',
    density: 8.96,
    thickness: 10,
    purity: 99.9,
  );
  static const Solvent _defaultSolvent = Solvent(
    name: 'NMP',
    density: 1.03,
    boilingPoint: 202,
    dielectricConstant: 32,
  );

  /// 모든 실험 가져오기
  List<Experiment> getAll() {
    return List.unmodifiable(_experiments);
  }

  Future<void> init() async {
    await DBHelper.instance.restoreSessionIfNeeded();
    final rows = await DBHelper.instance.getAllExperiments();
    _experiments.clear();
    if (rows.isEmpty) return;

    final protocols = {
      for (final p in ProtocolRepository.instance.getAll()) p.id: p,
    };
    final shouldValidateProtocolRefs = protocols.isNotEmpty;
    final usedNames = <String>{};

    for (final r in rows) {
      final rowId = (r['id'] as String?)?.trim() ?? '';
      final jsonStr = r['json'] as String?;
      if (jsonStr == null || jsonStr.isEmpty) {
        continue;
      }

      bool parsedWithFallback = false;
      Experiment experiment;
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is! Map) {
          throw const FormatException('Experiment payload is not a map');
        }
        experiment = _safeExperimentFromMap(
          rowId: rowId,
          raw: decoded.cast<String, Object?>(),
        );
      } catch (_) {
        parsedWithFallback = true;
        experiment = _fallbackExperiment(rowId: rowId, raw: null);
      }

      final repair = _repairExperiment(
        experiment: experiment,
        usedNames: usedNames,
        protocolById: protocols,
        validateProtocolReferences: shouldValidateProtocolRefs,
      );

      _experiments.add(repair.experiment);

      if (parsedWithFallback || repair.repaired || repair.experiment.id != rowId) {
        if (rowId.isNotEmpty && rowId != repair.experiment.id) {
          await DBHelper.instance.deleteExperiment(rowId);
        }
        await DBHelper.instance.upsertExperiment(
          repair.experiment.id,
          repair.experiment.toMap(),
        );
      }
    }
  }

  /// 실험 추가
  void add(Experiment experiment) {
    unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'experiment_add'));
    final usedNames = _experiments
        .where((e) => e.id != experiment.id)
        .map((e) => e.name.trim().toLowerCase())
        .toSet();
    final repair = _repairExperiment(
      experiment: experiment,
      usedNames: usedNames,
      protocolById: {
        for (final p in ProtocolRepository.instance.getAll()) p.id: p,
      },
      validateProtocolReferences: ProtocolRepository.instance.getAll().isNotEmpty,
    );

    final index = _experiments.indexWhere((e) => e.id == repair.experiment.id);
    if (index == -1) {
      _experiments.insert(0, repair.experiment);
    } else {
      _experiments[index] = repair.experiment;
    }
    unawaited(DBHelper.instance.upsertExperiment(repair.experiment.id, repair.experiment.toMap()));
  }

  /// 실험 삭제
  void remove(String experimentId) {
    unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'experiment_remove'));
    _experiments.removeWhere((experiment) => experiment.id == experimentId);
    unawaited(DBHelper.instance.deleteExperiment(experimentId));
  }

  /// 실험 수정
  void update(Experiment experiment) {
    final usedNames = _experiments
        .where((e) => e.id != experiment.id)
        .map((e) => e.name.trim().toLowerCase())
        .toSet();
    final repair = _repairExperiment(
      experiment: experiment,
      usedNames: usedNames,
      protocolById: {
        for (final p in ProtocolRepository.instance.getAll()) p.id: p,
      },
      validateProtocolReferences: ProtocolRepository.instance.getAll().isNotEmpty,
    );

    final index = _experiments.indexWhere(
      (e) => e.id == repair.experiment.id,
    );

    if (index != -1) {
      unawaited(DBHelper.instance.pushUndoSnapshot(reason: 'experiment_update'));
      _experiments[index] = repair.experiment;
      unawaited(DBHelper.instance.upsertExperiment(repair.experiment.id, repair.experiment.toMap()));
    }
  }

  /// ID로 찾기
  Experiment? findById(String id) {
    try {
      return _experiments.firstWhere(
        (experiment) => experiment.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  /// 테스트용 전체 삭제
  void clear() {
    _experiments.clear();
  }

  void replaceAll(List<Experiment> items) {
    _experiments
      ..clear()
      ..addAll(items);
  }

  int get count => _experiments.length;

  Future<void> createBackup({String label = 'manual'}) async {
    await DBHelper.instance.createBackup(label: label);
  }

  Future<bool> restoreLatestBackup() async {
    final ok = await DBHelper.instance.restoreLatestBackup();
    if (!ok) return false;
    await ProtocolRepository.instance.init();
    await init();
    return true;
  }

  Future<bool> undoLastChange() async {
    final ok = await DBHelper.instance.undoLast();
    if (!ok) return false;
    await ProtocolRepository.instance.init();
    await init();
    return true;
  }

  ExperimentSettings _defaultSettings() {
    return ExperimentSettings(
      material: _defaultMaterial,
      collector: _defaultCollector,
      solvent: _defaultSolvent,
      activeMaterial: 90,
      conductiveMaterial: 5,
      binder: 5,
      electrodeDiameter: 14,
      foilThickness: _defaultCollector.thickness,
      averageFoilWeight: 0,
      specificCapacity: _defaultMaterial.theoreticalCapacity,
      trueDensity: _defaultMaterial.density,
      dryingTemperature: 120,
      dryingTime: 12,
      rollPressPressure: 50,
    );
  }

  SharedValues _sharedFromSettings(ExperimentSettings settings) {
    return SharedValues(
      electrodeDiameter: settings.electrodeDiameter,
      foilThickness: settings.foilThickness,
      collector: settings.collector,
      averageFoilWeight: settings.averageFoilWeight,
      trueDensity: settings.trueDensity,
      specificCapacity: settings.specificCapacity,
      activeMaterialRatio: settings.activeMaterial,
      conductiveAdditiveRatio: settings.conductiveMaterial,
      binderRatio: settings.binder,
    );
  }

  Experiment _fallbackExperiment({
    required String rowId,
    Map<String, Object?>? raw,
  }) {
    final settings = _defaultSettings();
    final now = DateTime.now();
    final name = (raw?['name'] as String?)?.trim();
    return Experiment(
      id: rowId.isNotEmpty ? rowId : 'exp_${now.millisecondsSinceEpoch}',
      name: (name == null || name.isEmpty) ? 'Recovered Experiment' : name,
      createdAt: now,
      updatedAt: now,
      status: ExperimentStatus.active,
      settings: settings,
      sharedValues: _sharedFromSettings(settings),
      electrodes: const [],
      memo: (raw?['memo'] as String?) ?? '',
    );
  }

  Experiment _safeExperimentFromMap({
    required String rowId,
    required Map<String, Object?> raw,
  }) {
    final settings = _safeSettings(raw['settings']);
    final sharedValues = _safeSharedValues(raw['sharedValues'], settings);

    final statusRaw = raw['status'];
    int statusIndex = 0;
    if (statusRaw is num) {
      statusIndex = statusRaw.toInt();
    }
    if (statusIndex < 0 || statusIndex >= ExperimentStatus.values.length) {
      statusIndex = 0;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final createdAtMs = (raw['createdAt'] as num?)?.toInt() ?? nowMs;
    final updatedAtMs = (raw['updatedAt'] as num?)?.toInt() ?? nowMs;

    return Experiment(
      id: rowId.isNotEmpty
          ? rowId
          : ((raw['id'] as String?)?.trim().isNotEmpty ?? false)
              ? (raw['id'] as String).trim()
              : 'exp_${DateTime.now().millisecondsSinceEpoch}',
      name: ((raw['name'] as String?)?.trim().isNotEmpty ?? false)
          ? (raw['name'] as String).trim()
          : 'Recovered Experiment',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      status: ExperimentStatus.values[statusIndex],
      protocolId: (raw['protocolId'] as String?)?.trim(),
      protocolName: (raw['protocolName'] as String?)?.trim(),
      protocolVersion: (raw['protocolVersion'] as String?)?.trim(),
      settings: settings,
      sharedValues: sharedValues,
      electrodes: _safeElectrodeList(raw['electrodes']),
      memo: (raw['memo'] as String?) ?? '',
    );
  }

  ExperimentSettings _safeSettings(Object? raw) {
    if (raw is Map) {
      try {
        return ExperimentSettings.fromMap(raw.cast<String, Object?>());
      } catch (_) {
        // Repaired below using defaults.
      }
    }
    return _defaultSettings();
  }

  SharedValues _safeSharedValues(Object? raw, ExperimentSettings settings) {
    if (raw is Map) {
      try {
        return SharedValues.fromMap(raw.cast<String, Object?>());
      } catch (_) {
        // Repaired below using settings snapshot.
      }
    }
    return _sharedFromSettings(settings);
  }

  List<Electrode> _safeElectrodeList(Object? raw) {
    if (raw is! List) return <Electrode>[];

    final list = <Electrode>[];
    for (final item in raw) {
      if (item is! Map) continue;
      list.add(_safeElectrode(item.cast<String, Object?>()));
    }
    return list;
  }

  Electrode _safeElectrode(Map<String, Object?> raw) {
    final number = (raw['number'] as num?)?.toInt() ?? 0;

    ElectrodeInput input;
    final inputRaw = raw['input'];
    if (inputRaw is Map) {
      try {
        input = ElectrodeInput.fromMap(inputRaw.cast<String, Object?>());
      } catch (_) {
        input = ElectrodeInput();
      }
    } else {
      input = ElectrodeInput();
    }

    CalculationResult result;
    final resultRaw = raw['result'];
    if (resultRaw is Map) {
      try {
        result = CalculationResult.fromMap(resultRaw.cast<String, Object?>());
      } catch (_) {
        result = CalculationResult();
      }
    } else {
      result = CalculationResult();
    }

    final overrides = <String, double>{};
    final overridesRaw = raw['valueOverrides'];
    if (overridesRaw is Map) {
      for (final entry in overridesRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is num) {
          overrides[key] = value.toDouble();
        }
      }
    }

    final images = <String>[];
    final imagesRaw = raw['images'];
    if (imagesRaw is List) {
      for (final image in imagesRaw) {
        if (image is String && image.trim().isNotEmpty) {
          images.add(image);
        }
      }
    }

    return Electrode(
      number: number,
      input: input,
      result: result,
      valueOverrides: overrides,
      memo: (raw['memo'] as String?) ?? '',
      images: images,
    );
  }

  _IntegrityRepairResult _repairExperiment({
    required Experiment experiment,
    required Set<String> usedNames,
    required Map<String, Protocol> protocolById,
    required bool validateProtocolReferences,
  }) {
    bool repaired = false;

    final canonicalName = experiment.name.trim().isEmpty
        ? 'Recovered Experiment'
        : experiment.name.trim();
    final uniqueName = _ensureUniqueName(canonicalName, usedNames);
    if (uniqueName != experiment.name) {
      repaired = true;
      experiment.name = uniqueName;
    }

    if (experiment.updatedAt.isBefore(experiment.createdAt)) {
      repaired = true;
      experiment.updatedAt = experiment.createdAt;
    }

    final sharedRepair = _repairSharedValues(
      shared: experiment.sharedValues,
      settings: experiment.settings,
    );
    if (sharedRepair.repaired) {
      repaired = true;
      experiment.sharedValues = sharedRepair.shared;
    }

    final electrodeRepair = _repairElectrodes(
      electrodes: experiment.electrodes,
      shared: experiment.sharedValues,
    );
    if (electrodeRepair.repaired) {
      repaired = true;
      experiment.electrodes = electrodeRepair.electrodes;
    }

    if (validateProtocolReferences) {
      final protocolId = experiment.protocolId?.trim();
      if (protocolId == null || protocolId.isEmpty) {
        if (experiment.protocolId != null || experiment.protocolName != null || experiment.protocolVersion != null) {
          repaired = true;
          experiment.protocolId = null;
          experiment.protocolName = null;
          experiment.protocolVersion = null;
        }
      } else {
        final protocol = protocolById[protocolId];
        if (protocol == null || !_isProtocolValid(protocol)) {
          repaired = true;
          experiment.protocolId = null;
          experiment.protocolName = null;
          experiment.protocolVersion = null;
        } else {
          if (experiment.protocolName != protocol.name) {
            repaired = true;
            experiment.protocolName = protocol.name;
          }
          if (experiment.protocolVersion != protocol.version) {
            repaired = true;
            experiment.protocolVersion = protocol.version;
          }
        }
      }
    }

    return _IntegrityRepairResult(experiment: experiment, repaired: repaired);
  }

  String _ensureUniqueName(String baseName, Set<String> usedNames) {
    var candidate = baseName;
    var index = 2;
    while (usedNames.contains(candidate.toLowerCase())) {
      candidate = '$baseName ($index)';
      index += 1;
    }
    usedNames.add(candidate.toLowerCase());
    return candidate;
  }

  ({SharedValues shared, bool repaired}) _repairSharedValues({
    required SharedValues shared,
    required ExperimentSettings settings,
  }) {
    bool repaired = false;
    var collectorPreset = shared.collectorPreset;
    var activeMaterial = shared.activeMaterial;
    var electrodeDiameter = shared.electrodeDiameter;
    var foilThickness = shared.foilThickness;
    var collector = shared.collector;
    var averageFoilWeight = shared.averageFoilWeight;
    var trueDensity = shared.trueDensity;
    var specificCapacity = shared.specificCapacity;
    var active = shared.activeMaterialRatio;
    var conductive = shared.conductiveAdditiveRatio;
    var binder = shared.binderRatio;
    var pressEnabled = shared.pressEnabled;
    var targetPorosity = shared.targetPorosity;

    if (collectorPreset.trim().isEmpty) {
      repaired = true;
      collectorPreset = collector.name;
    }
    if (activeMaterial.trim().isEmpty) {
      repaired = true;
      activeMaterial = settings.material.name.trim().isNotEmpty
          ? settings.material.name
          : 'Active Material';
    }

    if (electrodeDiameter <= 0) {
      repaired = true;
      electrodeDiameter = settings.electrodeDiameter > 0 ? settings.electrodeDiameter : 14;
    }
    if (foilThickness < 0) {
      repaired = true;
      foilThickness = settings.foilThickness >= 0 ? settings.foilThickness : 10;
    }
    if (averageFoilWeight < 0) {
      repaired = true;
      averageFoilWeight = settings.averageFoilWeight >= 0 ? settings.averageFoilWeight : 0;
    }
    if (trueDensity <= 0) {
      repaired = true;
      trueDensity = settings.trueDensity > 0 ? settings.trueDensity : 1.55;
    }
    if (specificCapacity < 0) {
      repaired = true;
      specificCapacity = settings.specificCapacity >= 0 ? settings.specificCapacity : 300;
    }
    if (targetPorosity < 0 || targetPorosity >= 100) {
      repaired = true;
      targetPorosity = 0;
      pressEnabled = false;
    }

    if (collector.name.trim().isEmpty || collector.density <= 0 || collector.thickness < 0 || collector.purity <= 0) {
      repaired = true;
      collector = settings.collector.name.trim().isNotEmpty
          ? settings.collector
          : _defaultCollector;
    }

    if (active < 0 || conductive < 0 || binder < 0) {
      repaired = true;
      active = active < 0 ? 0 : active;
      conductive = conductive < 0 ? 0 : conductive;
      binder = binder < 0 ? 0 : binder;
    }

    final sum = active + conductive + binder;
    if (sum <= 0) {
      repaired = true;
      active = settings.activeMaterial > 0 ? settings.activeMaterial : 90;
      conductive = settings.conductiveMaterial >= 0 ? settings.conductiveMaterial : 5;
      binder = settings.binder >= 0 ? settings.binder : 5;
    } else if ((sum - 100).abs() > 1e-6) {
      repaired = true;
      active = (active / sum) * 100;
      conductive = (conductive / sum) * 100;
      binder = (binder / sum) * 100;
    }

    if (!repaired) {
      return (shared: shared, repaired: false);
    }

    return (
      shared: SharedValues(
        collectorPreset: collectorPreset,
        activeMaterial: activeMaterial,
        electrodeDiameter: electrodeDiameter,
        foilThickness: foilThickness,
        collector: collector,
        averageFoilWeight: averageFoilWeight,
        trueDensity: trueDensity,
        specificCapacity: specificCapacity,
        activeMaterialRatio: active,
        conductiveAdditiveRatio: conductive,
        binderRatio: binder,
        pressEnabled: pressEnabled,
        targetPorosity: pressEnabled ? targetPorosity : 0,
      ),
      repaired: true,
    );
  }

  ({List<Electrode> electrodes, bool repaired}) _repairElectrodes({
    required List<Electrode> electrodes,
    required SharedValues shared,
  }) {
    bool repaired = false;
    final usedNumbers = <int>{};
    final repairedElectrodes = <Electrode>[];

    for (var i = 0; i < electrodes.length; i++) {
      final original = electrodes[i];
      var number = original.number;
      if (number <= 0 || usedNumbers.contains(number)) {
        repaired = true;
        number = _nextElectrodeNumber(usedNumbers);
      }
      usedNumbers.add(number);

      final sanitizedInput = _sanitizeElectrodeInput(original.input, shared);
      if (!identical(sanitizedInput, original.input)) {
        repaired = true;
      }

      final sanitizedOverrides = <String, double>{};
      for (final entry in original.valueOverrides.entries) {
        if (entry.value.isFinite) {
          sanitizedOverrides[entry.key] = entry.value;
        } else {
          repaired = true;
        }
      }

      CalculationResult result = original.result;
      if (_isMissingResult(result)) {
        repaired = true;
        result = CalculationService.calculateForElectrode(
          electrode: Electrode(
            number: number,
            input: sanitizedInput,
            result: CalculationResult(),
            valueOverrides: sanitizedOverrides,
            memo: original.memo,
            images: original.images,
          ),
          activeMaterialRatioPercent: shared.activeMaterialRatio,
          specificCapacity: shared.specificCapacity,
          trueDensity: shared.trueDensity,
          foilWeightMg: shared.averageFoilWeight,
          foilThicknessUm: shared.foilThickness,
        );
      }

      repairedElectrodes.add(
        Electrode(
          number: number,
          input: sanitizedInput,
          result: result,
          valueOverrides: sanitizedOverrides,
          memo: original.memo,
          images: original.images,
        ),
      );
    }

    return (electrodes: repairedElectrodes, repaired: repaired);
  }

  ElectrodeInput _sanitizeElectrodeInput(ElectrodeInput input, SharedValues shared) {
    final totalMass = input.totalMass.isFinite && input.totalMass >= 0 ? input.totalMass : 0.0;
    final collectorMass = input.collectorMass.isFinite && input.collectorMass >= 0 ? input.collectorMass : 0.0;
    final diameter = input.diameter.isFinite && input.diameter > 0
        ? input.diameter
      : (shared.electrodeDiameter > 0 ? shared.electrodeDiameter : 14.0);
    final thickness = input.thickness.isFinite && input.thickness >= 0 ? input.thickness : 0.0;

    final changed =
        totalMass != input.totalMass ||
        collectorMass != input.collectorMass ||
        diameter != input.diameter ||
        thickness != input.thickness;

    if (!changed) {
      return input;
    }

    return ElectrodeInput(
      totalMass: totalMass,
      collectorMass: collectorMass,
      diameter: diameter,
      thickness: thickness,
      memo: input.memo,
    );
  }

  bool _isMissingResult(CalculationResult r) {
    final allStatesEmpty =
        r.areaState == CalculationState.empty &&
        r.activeMaterialMassState == CalculationState.empty &&
        r.loadingState == CalculationState.empty &&
        r.arealCapacityState == CalculationState.empty &&
        r.electrodeDensityState == CalculationState.empty &&
        r.porosityState == CalculationState.empty &&
        r.theoreticalCapacityState == CalculationState.empty;

    final allValuesZero =
        r.area == 0 &&
        r.activeMaterialMass == 0 &&
        r.loading == 0 &&
        r.arealCapacity == 0 &&
        r.electrodeDensity == 0 &&
        r.porosity == 0 &&
        r.theoreticalCapacity == 0;

    return allStatesEmpty && allValuesZero;
  }

  int _nextElectrodeNumber(Set<int> used) {
    var n = 1;
    while (used.contains(n)) {
      n += 1;
    }
    return n;
  }

  bool _isProtocolValid(Protocol protocol) {
    if (protocol.name.trim().isEmpty) return false;
    if (protocol.materialName.trim().isEmpty) return false;
    if (protocol.collectorName.trim().isEmpty) return false;
    if (protocol.specificCapacity < 0 || protocol.trueDensity <= 0) return false;
    if (protocol.diameter <= 0 || protocol.collectorThickness < 0 || protocol.collectorDensity <= 0 || protocol.averageFoilWeight < 0) return false;
    if (protocol.targetPorosity < 0 || protocol.targetPorosity >= 100) return false;
    if (protocol.solidContent <= 0 || protocol.solidContent > 1) return false;

    final ratios = [protocol.activeRatio, protocol.conductiveRatio, protocol.binderRatio];
    if (ratios.any((v) => v < 0 || v > 100)) return false;
    final ratioSum = protocol.activeRatio + protocol.conductiveRatio + protocol.binderRatio;
    if ((ratioSum - 100).abs() > 0.01) return false;

    return true;
  }
}