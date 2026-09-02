import 'calculation_result.dart';
import 'electrode_input.dart';
import 'shared_values.dart';

class Electrode {
  static const String keyMaterialPresetId = 'materialPresetId';
  static const String keyCollectorPresetId = 'collectorPresetId';
  static const String keyActiveMaterialRatio = 'activeMaterialRatio';
  static const String keyConductiveAdditiveRatio = 'conductiveAdditiveRatio';
  static const String keyBinderRatio = 'binderRatio';
  static const String keyPunchDiameter = 'punchDiameter';
  static const String keyElectrodeDiameter = 'electrodeDiameter';
  static const String keyPressEnabled = 'pressEnabled';
  static const String keyTargetPorosity = 'targetPorosity';
  static const String keySpecificCapacity = 'specificCapacity';
  static const String keyTrueDensity = 'trueDensity';
  static const String keyAverageFoilWeight = 'averageFoilWeight';
  static const String keyFoilThickness = 'foilThickness';

  /// Electrode Number
  int number;

  /// Input Values
  ElectrodeInput input;

  /// Calculated Results
  CalculationResult result;

  /// Per-electrode override values for experiment-shared settings.
  Map<String, double> valueOverrides;

  /// Optional per-electrode string overrides (for preset/name style shared values).
  Map<String, String> stringOverrides;

  /// Optional per-electrode boolean overrides (for flags like pressEnabled).
  Map<String, bool> boolOverrides;

  /// Optional Memo
  String memo;

  /// Image Paths
  List<String> images;

  Electrode({
    required this.number,
    required this.input,
    required this.result,
    this.valueOverrides = const {},
    this.stringOverrides = const {},
    this.boolOverrides = const {},
    this.memo = '',
    this.images = const [],
  });

  bool hasOverride(String key) => valueOverrides.containsKey(key);

  void setOverride(String key, double value) {
    valueOverrides = Map<String, double>.from(valueOverrides)..[key] = value;
  }

  void clearOverride(String key) {
    if (hasOverride(key)) {
      valueOverrides = Map<String, double>.from(valueOverrides)..remove(key);
    }
  }

  bool hasStringOverride(String key) => stringOverrides.containsKey(key);

  void setStringOverride(String key, String value) {
    stringOverrides = Map<String, String>.from(stringOverrides)..[key] = value;
  }

  void clearStringOverride(String key) {
    if (hasStringOverride(key)) {
      stringOverrides = Map<String, String>.from(stringOverrides)..remove(key);
    }
  }

  bool hasBoolOverride(String key) => boolOverrides.containsKey(key);

  void setBoolOverride(String key, bool value) {
    boolOverrides = Map<String, bool>.from(boolOverrides)..[key] = value;
  }

  void clearBoolOverride(String key) {
    if (hasBoolOverride(key)) {
      boolOverrides = Map<String, bool>.from(boolOverrides)..remove(key);
    }
  }

  double resolveValue(String key, double fallback) {
    return valueOverrides[key] ?? fallback;
  }

  double resolveSharedNumber(String key, SharedValues sharedValues) {
    return valueOverrides[key] ?? sharedValues.resolveNumericValue(key);
  }

  bool resolveSharedBool(String key, SharedValues sharedValues) {
    return boolOverrides[key] ?? sharedValues.resolveBoolValue(key);
  }

  String? resolveSharedString(String key, SharedValues sharedValues) {
    return stringOverrides[key] ?? sharedValues.resolveStringValue(key);
  }

  Map<String, Object?> toMap() {
    return {
      'number': number,
      'input': input.toMap(),
      'result': result.toMap(),
      'valueOverrides': valueOverrides,
      'stringOverrides': stringOverrides,
      'boolOverrides': boolOverrides,
      'memo': memo,
      'images': images,
    };
  }

  static Electrode fromMap(Map<String, Object?> m) {
    final inputMap = (m['input'] is Map)
        ? (m['input'] as Map).cast<String, Object?>()
        : <String, Object?>{};
    final resultMap = (m['result'] is Map)
        ? (m['result'] as Map).cast<String, Object?>()
        : <String, Object?>{};

    final parsedOverrides = <String, double>{};
    final rawOverrides = m['valueOverrides'];
    if (rawOverrides is Map) {
      for (final entry in rawOverrides.entries) {
        final value = entry.value;
        if (value is num) {
          parsedOverrides[entry.key.toString()] = value.toDouble();
        }
      }
    }

    final parsedStringOverrides = <String, String>{};
    final rawStringOverrides = m['stringOverrides'];
    if (rawStringOverrides is Map) {
      for (final entry in rawStringOverrides.entries) {
        final value = entry.value;
        if (value is String) {
          parsedStringOverrides[entry.key.toString()] = value;
        }
      }
    }

    final parsedBoolOverrides = <String, bool>{};
    final rawBoolOverrides = m['boolOverrides'];
    if (rawBoolOverrides is Map) {
      for (final entry in rawBoolOverrides.entries) {
        final value = entry.value;
        if (value is bool) {
          parsedBoolOverrides[entry.key.toString()] = value;
        }
      }
    }

    return Electrode(
      number: (m['number'] as num?)?.toInt() ?? 0,
      input: ElectrodeInput.fromMap(inputMap),
      result: CalculationResult.fromMap(resultMap),
      valueOverrides: parsedOverrides,
      stringOverrides: parsedStringOverrides,
      boolOverrides: parsedBoolOverrides,
      memo: m['memo'] as String? ?? '',
      images: (m['images'] as List?)?.cast<String>() ?? [],
    );
  }
}