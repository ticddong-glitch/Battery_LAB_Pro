import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

class SQLiteHelper {
	SQLiteHelper._();

	static final SQLiteHelper instance = SQLiteHelper._();
	static Database? _db;

	Future<Database> get database async {
		if (_db != null) return _db!;

		final databasesPath = await getDatabasesPath();
		final path = p.join(databasesPath, 'lab_calculator.db');
		_db = await openDatabase(path);

		await ensureMaterialPresetTable();
		await ensureCollectorPresetTable();
		return _db!;
	}

	Future<void> ensureMaterialPresetTable() async {
		final db = await database;
		await db.execute('''
			CREATE TABLE IF NOT EXISTS ${DatabaseTables.materialPresets} (
				${MaterialPresetColumns.id} TEXT PRIMARY KEY,
				${MaterialPresetColumns.name} TEXT NOT NULL,
				${MaterialPresetColumns.category} TEXT NOT NULL,
				${MaterialPresetColumns.trueDensity} REAL NOT NULL,
				${MaterialPresetColumns.specificCapacity} REAL,
				${MaterialPresetColumns.memo} TEXT NOT NULL DEFAULT ''
			)
		''');
	}

	Future<void> ensureCollectorPresetTable() async {
		final db = await database;
		await db.execute('''
			CREATE TABLE IF NOT EXISTS ${DatabaseTables.collectorPresets} (
				${CollectorPresetColumns.id} TEXT PRIMARY KEY,
				${CollectorPresetColumns.presetName} TEXT NOT NULL,
				${CollectorPresetColumns.collectorMaterial} TEXT NOT NULL,
				${CollectorPresetColumns.thickness} REAL NOT NULL,
				${CollectorPresetColumns.punchDiameter} REAL NOT NULL,
				${CollectorPresetColumns.averageFoilWeight} REAL NOT NULL,
				${CollectorPresetColumns.memo} TEXT NOT NULL DEFAULT ''
			)
		''');
	}

	Future<int> insert(
		String table,
		Map<String, Object?> values, {
		ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
	}) async {
		final db = await database;
		return db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
	}

	Future<int> update(
		String table,
		Map<String, Object?> values, {
		required String where,
		required List<Object?> whereArgs,
	}) async {
		final db = await database;
		return db.update(table, values, where: where, whereArgs: whereArgs);
	}

	Future<int> delete(
		String table, {
		required String where,
		required List<Object?> whereArgs,
	}) async {
		final db = await database;
		return db.delete(table, where: where, whereArgs: whereArgs);
	}

	Future<List<Map<String, Object?>>> getAll(
		String table, {
		String? orderBy,
	}) async {
		final db = await database;
		return db.query(table, orderBy: orderBy);
	}
}
