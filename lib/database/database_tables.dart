class DatabaseTables {
	DatabaseTables._();

	static const String materialPresets = 'material_presets';
	static const String collectorPresets = 'collector_presets';
}

class MaterialPresetColumns {
	MaterialPresetColumns._();

	static const String id = 'id';
	static const String name = 'name';
	static const String category = 'category';
	static const String trueDensity = 'trueDensity';
	static const String specificCapacity = 'specificCapacity';
	static const String memo = 'memo';
}

class CollectorPresetColumns {
	CollectorPresetColumns._();

	static const String id = 'id';
	static const String presetName = 'presetName';
	static const String collectorMaterial = 'collectorMaterial';
	static const String thickness = 'thickness';
	static const String punchDiameter = 'punchDiameter';
	static const String averageFoilWeight = 'averageFoilWeight';
	static const String memo = 'memo';
}
