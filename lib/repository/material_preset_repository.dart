import '../models/presets/material_preset.dart';
import '../database/database_tables.dart';
import '../database/sqlite_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class MaterialPresetRepository {
	Future<List<MaterialPreset>> getAll();

	Future<void> insert(MaterialPreset item);

	Future<void> update(MaterialPreset item);

	Future<void> delete(String id);
}

class SQLiteMaterialPresetRepository implements MaterialPresetRepository {
	SQLiteMaterialPresetRepository({
		SQLiteHelper? helper,
	}) : helper = helper ?? SQLiteHelper.instance;

	final SQLiteHelper helper;

	@override
	Future<void> insert(MaterialPreset item) async {
		await helper.ensureMaterialPresetTable();
		await helper.insert(
			DatabaseTables.materialPresets,
			item.toMap(),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	@override
	Future<void> update(MaterialPreset item) async {
		await helper.ensureMaterialPresetTable();
		await helper.update(
			DatabaseTables.materialPresets,
			item.toMap(),
			where: '${MaterialPresetColumns.id} = ?',
			whereArgs: [item.id],
		);
	}

	@override
	Future<void> delete(String id) async {
		await helper.ensureMaterialPresetTable();
		await helper.delete(
			DatabaseTables.materialPresets,
			where: '${MaterialPresetColumns.id} = ?',
			whereArgs: [id],
		);
	}

	@override
	Future<List<MaterialPreset>> getAll() async {
		await helper.ensureMaterialPresetTable();
		final rows = await helper.getAll(
			DatabaseTables.materialPresets,
			orderBy: '${MaterialPresetColumns.name} COLLATE NOCASE ASC',
		);

		return rows
				.map((row) => MaterialPreset.fromMap(row))
				.toList(growable: false);
	}
}
