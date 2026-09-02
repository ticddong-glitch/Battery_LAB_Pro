import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'lab_calculator.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE protocols (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE experiments (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT,
        json TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE undo_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reason TEXT,
        json TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE session_state (
        key TEXT PRIMARY KEY,
        value TEXT,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS backups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          label TEXT,
          json TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS undo_snapshots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reason TEXT,
          json TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_state (
          key TEXT PRIMARY KEY,
          value TEXT,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_preferences (
          key TEXT PRIMARY KEY,
          value TEXT,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }
  }

  // Protocols
  Future<void> upsertProtocol(String id, Map<String, Object?> map) async {
    final db = await database;
    final jsonStr = jsonEncode(map);
    await db.insert(
      'protocols',
      {'id': id, 'json': jsonStr},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllProtocols() async {
    final db = await database;
    final rows = await db.query('protocols');
    return rows
        .map((r) => {'id': r['id'], 'json': r['json']})
        .toList();
  }

  Future<void> deleteProtocol(String id) async {
    final db = await database;
    await db.delete('protocols', where: 'id = ?', whereArgs: [id]);
  }

  // Experiments
  Future<void> upsertExperiment(String id, Map<String, Object?> map) async {
    final db = await database;
    final jsonStr = jsonEncode(map);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('experiments', columns: ['createdAt'], where: 'id = ?', whereArgs: [id], limit: 1);
    final createdAt = existing.isNotEmpty ? (existing.first['createdAt'] as int? ?? now) : now;
    await db.insert(
      'experiments',
      {'id': id, 'json': jsonStr, 'createdAt': createdAt, 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllExperiments() async {
    final db = await database;
    final rows = await db.query('experiments', orderBy: 'createdAt DESC');
    return rows.map((r) => {'id': r['id'], 'json': r['json']}).toList();
  }

  Future<void> deleteExperiment(String id) async {
    final db = await database;
    await db.delete('experiments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Object?>> _captureSnapshot() async {
    final db = await database;
    final protocolRows = await db.query('protocols', orderBy: 'id ASC');
    final experimentRows = await db.query('experiments', orderBy: 'createdAt DESC');

    return {
      'protocols': protocolRows
          .map((r) => {'id': r['id'], 'json': r['json']})
          .toList(),
      'experiments': experimentRows
          .map((r) => {
                'id': r['id'],
                'json': r['json'],
                'createdAt': r['createdAt'],
                'updatedAt': r['updatedAt'],
              })
          .toList(),
    };
  }

  Future<void> createBackup({String label = 'manual'}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _captureSnapshot();
    await db.insert('backups', {
      'label': label,
      'json': jsonEncode(snapshot),
      'createdAt': now,
    });
  }

  Future<List<Map<String, Object?>>> getBackups() async {
    final db = await database;
    return db.query('backups', orderBy: 'createdAt DESC');
  }

  Future<void> pushUndoSnapshot({String reason = 'mutation', int maxEntries = 20}) async {
    final db = await database;
    final snapshot = await _captureSnapshot();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('undo_snapshots', {
      'reason': reason,
      'json': jsonEncode(snapshot),
      'createdAt': now,
    });

    final rows = await db.query('undo_snapshots', columns: ['id'], orderBy: 'createdAt DESC');
    if (rows.length > maxEntries) {
      final extra = rows.skip(maxEntries).map((e) => e['id']).whereType<int>().toList();
      if (extra.isNotEmpty) {
        final placeholders = List.filled(extra.length, '?').join(',');
        await db.delete('undo_snapshots', where: 'id IN ($placeholders)', whereArgs: extra);
      }
    }
  }

  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    final db = await database;
    final protocols = (snapshot['protocols'] as List?) ?? const [];
    final experiments = (snapshot['experiments'] as List?) ?? const [];

    await db.transaction((txn) async {
      await txn.delete('protocols');
      await txn.delete('experiments');

      for (final p in protocols) {
        final map = (p as Map).cast<String, Object?>();
        await txn.insert('protocols', {
          'id': map['id'],
          'json': map['json'],
        });
      }

      for (final e in experiments) {
        final map = (e as Map).cast<String, Object?>();
        await txn.insert('experiments', {
          'id': map['id'],
          'json': map['json'],
          'createdAt': map['createdAt'],
          'updatedAt': map['updatedAt'],
        });
      }
    });
  }

  Future<bool> restoreBackup(int backupId) async {
    final db = await database;
    final rows = await db.query('backups', where: 'id = ?', whereArgs: [backupId], limit: 1);
    if (rows.isEmpty) return false;
    final jsonStr = rows.first['json'] as String;
    final snapshot = jsonDecode(jsonStr) as Map<String, dynamic>;
    await _applySnapshot(snapshot);
    return true;
  }

  Future<bool> restoreLatestBackup() async {
    final db = await database;
    final rows = await db.query('backups', columns: ['id'], orderBy: 'createdAt DESC', limit: 1);
    if (rows.isEmpty) return false;
    final backupId = rows.first['id'] as int;
    return restoreBackup(backupId);
  }

  Future<bool> undoLast() async {
    final db = await database;
    final rows = await db.query('undo_snapshots', orderBy: 'createdAt DESC', limit: 1);
    if (rows.isEmpty) return false;

    final row = rows.first;
    final id = row['id'] as int;
    final jsonStr = row['json'] as String;
    final snapshot = jsonDecode(jsonStr) as Map<String, dynamic>;
    await _applySnapshot(snapshot);
    await db.delete('undo_snapshots', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<void> setSessionValue(String key, String value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'session_state',
      {'key': key, 'value': value, 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSessionValue(String key) async {
    final db = await database;
    final rows = await db.query('session_state', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> restoreSessionIfNeeded() async {
    final db = await database;
    final expCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM experiments')) ?? 0;
    final protoCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM protocols')) ?? 0;
    if (expCount == 0 && protoCount == 0) {
      await restoreLatestBackup();
    }
  }

  Future<void> setPreference(String key, String value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_preferences',
      {'key': key, 'value': value, 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final rows = await db.query('app_preferences', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
