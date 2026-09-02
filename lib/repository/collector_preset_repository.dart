import '../models/presets/collector_preset.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_tables.dart';
import '../database/sqlite_helper.dart';

abstract class CollectorPresetRepository {
	Future<List<CollectorPreset>> getAll();

	Future<void> insert(CollectorPreset item);

	Future<void> update(CollectorPreset item);

	Future<void> delete(String id);
}

class SQLiteCollectorPresetRepository implements CollectorPresetRepository {
	SQLiteCollectorPresetRepository({
		SQLiteHelper? helper,
	}) : helper = helper ?? SQLiteHelper.instance;

	final SQLiteHelper helper;

	@override
	Future<void> insert(CollectorPreset item) async {
		await helper.ensureCollectorPresetTable();
		await helper.insert(
			DatabaseTables.collectorPresets,
			item.toMap(),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	@override
	Future<void> update(CollectorPreset item) async {
		await helper.ensureCollectorPresetTable();
		await helper.update(
			DatabaseTables.collectorPresets,
			item.toMap(),
			where: '${CollectorPresetColumns.id} = ?',
			whereArgs: [item.id],
		);
	}

	@override
	Future<void> delete(String id) async {
		await helper.ensureCollectorPresetTable();
		await helper.delete(
			DatabaseTables.collectorPresets,
			where: '${CollectorPresetColumns.id} = ?',
			whereArgs: [id],
		);
	}

	@override
	Future<List<CollectorPreset>> getAll() async {
		await helper.ensureCollectorPresetTable();
		final rows = await helper.getAll(
			DatabaseTables.collectorPresets,
			orderBy: '${CollectorPresetColumns.presetName} COLLATE NOCASE ASC',
		);

		return rows.map(CollectorPreset.fromMap).toList(growable: false);
	}
}
