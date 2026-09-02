import 'battery_material.dart';
import 'presets/collector_preset.dart';
import 'current_collector.dart';
import 'presets/material_preset.dart';

enum ThemePreference { system, light, dark }

enum UnitPreference { metric, lab }

class AppPreferences {
  final UnitPreference units;
  final int decimalPlaces;
  final List<MaterialPreset> materialPresets;
  final List<CollectorPreset> collectorPresets;
  final String defaultExportFolder;
  final ThemePreference theme;
  final String languageCode;

  const AppPreferences({
    required this.units,
    required this.decimalPlaces,
    required this.materialPresets,
    required this.collectorPresets,
    required this.defaultExportFolder,
    required this.theme,
    required this.languageCode,
  });

  factory AppPreferences.defaults() {
    return AppPreferences(
      units: UnitPreference.metric,
      decimalPlaces: 2,
      materialPresets: const [
        MaterialPreset(
          id: 'mat_hard_carbon',
          name: 'Hard Carbon',
          category: MaterialCategory.activeMaterial,
          trueDensity: 1.55,
          specificCapacity: 300,
          memo: 'Default active material',
          isCustom: false,
        ),
        MaterialPreset(
          id: 'mat_super_p',
          name: 'Super P',
          category: MaterialCategory.conductiveAdditive,
          trueDensity: 1.95,
          memo: 'Default conductive additive',
          isCustom: false,
        ),
        MaterialPreset(
          id: 'mat_pvdf',
          name: 'PVDF',
          category: MaterialCategory.binder,
          trueDensity: 1.78,
          memo: 'Default binder',
          isCustom: false,
        ),
      ],
      collectorPresets: const [
        CollectorPreset(
          id: 'col_cu_14',
          presetName: 'Cu Foil 14mm',
          collectorMaterial: 'Cu Foil',
          thickness: 10,
          density: 8.96,
          punchDiameter: 14,
          averageFoilWeight: 0,
          memo: 'Default copper collector preset',
          isCustom: false,
        ),
        CollectorPreset(
          id: 'col_al_14',
          presetName: 'Al Foil 14mm',
          collectorMaterial: 'Al Foil',
          thickness: 15,
          density: 2.70,
          punchDiameter: 14,
          averageFoilWeight: 0,
          memo: 'Default aluminum collector preset',
          isCustom: false,
        ),
      ],
      defaultExportFolder: '',
      theme: ThemePreference.light,
      languageCode: 'en',
    );
  }

  AppPreferences copyWith({
    UnitPreference? units,
    int? decimalPlaces,
    List<MaterialPreset>? materialPresets,
    List<CollectorPreset>? collectorPresets,
    String? defaultExportFolder,
    ThemePreference? theme,
    String? languageCode,
  }) {
    return AppPreferences(
      units: units ?? this.units,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      materialPresets: materialPresets ?? this.materialPresets,
      collectorPresets: collectorPresets ?? this.collectorPresets,
      defaultExportFolder: defaultExportFolder ?? this.defaultExportFolder,
      theme: theme ?? this.theme,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'units': units.name,
      'decimalPlaces': decimalPlaces,
      'materialPresets': materialPresets.map((m) => m.toMap()).toList(),
      'collectorPresets': collectorPresets.map((c) => c.toMap()).toList(),
      'defaultExportFolder': defaultExportFolder,
      'theme': theme.name,
      'languageCode': languageCode,
    };
  }

  List<BatteryMaterial> get materialDatabase {
    return materialPresets
        .where((m) => m.category == MaterialCategory.activeMaterial)
        .map(
          (m) => BatteryMaterial(
            name: m.name,
            theoreticalCapacity: m.specificCapacity ?? 0,
            density: m.trueDensity,
            description: m.memo,
          ),
        )
        .toList();
  }

  List<CurrentCollector> get collectorDatabase {
    return collectorPresets
        .map(
          (c) => CurrentCollector(
            name: c.collectorMaterial,
            density: c.density,
            thickness: c.thickness,
            purity: 99.9,
          ),
        )
        .toList();
  }

  static AppPreferences fromMap(Map<String, Object?> map) {
    final rawMaterialPresets = (map['materialPresets'] as List?) ?? const [];
    final rawCollectorPresets = (map['collectorPresets'] as List?) ?? const [];
    final rawLegacyMaterials = (map['materialDatabase'] as List?) ?? const [];
    final rawLegacyCollectors = (map['collectorDatabase'] as List?) ?? const [];

    final parsedMaterialPresets = rawMaterialPresets
        .whereType<Map>()
        .map((e) => MaterialPreset.fromMap(e.cast<String, Object?>()))
        .toList();

    final parsedCollectorPresets = rawCollectorPresets
        .whereType<Map>()
        .map((e) => CollectorPreset.fromMap(e.cast<String, Object?>()))
        .toList();

    if (parsedMaterialPresets.isEmpty && rawLegacyMaterials.isNotEmpty) {
      for (final entry in rawLegacyMaterials.whereType<Map>()) {
        final m = entry.cast<String, Object?>();
        parsedMaterialPresets.add(
          MaterialPreset(
            id: 'legacy_mat_${parsedMaterialPresets.length}_${DateTime.now().millisecondsSinceEpoch}',
            name: (m['name'] as String?) ?? 'Material',
            category: MaterialCategory.activeMaterial,
            trueDensity: (m['density'] as num?)?.toDouble() ?? 0,
            specificCapacity: (m['theoreticalCapacity'] as num?)?.toDouble(),
            memo: (m['description'] as String?) ?? '',
          ),
        );
      }
    }

    if (parsedCollectorPresets.isEmpty && rawLegacyCollectors.isNotEmpty) {
      for (final entry in rawLegacyCollectors.whereType<Map>()) {
        final c = entry.cast<String, Object?>();
        parsedCollectorPresets.add(
          CollectorPreset(
            id: 'legacy_col_${parsedCollectorPresets.length}_${DateTime.now().millisecondsSinceEpoch}',
            presetName: (c['name'] as String?) ?? 'Collector',
            collectorMaterial: (c['name'] as String?) ?? '',
            thickness: (c['thickness'] as num?)?.toDouble() ?? 0,
            punchDiameter: 14,
            averageFoilWeight: 0,
            memo: 'Migrated from legacy collector database',
          ),
        );
      }
    }

    final defaults = AppPreferences.defaults();

    return AppPreferences(
      units: UnitPreference.values.firstWhere(
        (u) => u.name == (map['units'] as String? ?? 'metric'),
        orElse: () => UnitPreference.metric,
      ),
      decimalPlaces: (map['decimalPlaces'] as int?) ?? 2,
      materialPresets: parsedMaterialPresets.isEmpty ? defaults.materialPresets : parsedMaterialPresets,
      collectorPresets: parsedCollectorPresets.isEmpty ? defaults.collectorPresets : parsedCollectorPresets,
      defaultExportFolder: map['defaultExportFolder'] as String? ?? '',
      theme: ThemePreference.values.firstWhere(
        (t) => t.name == (map['theme'] as String? ?? 'light'),
        orElse: () => ThemePreference.light,
      ),
      languageCode: map['languageCode'] as String? ?? 'en',
    );
  }
}
