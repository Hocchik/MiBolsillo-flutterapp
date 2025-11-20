import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Simple local SQLite wrapper for transactions/goals and a sync queue.
///
/// - Tables:
///   - transactions
///   - goals
///   - sync_queue (pending client changes)
class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'tubolsillo.db');

    _db = await openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId TEXT UNIQUE,
          serverId TEXT,
          userId TEXT,
          type TEXT,
          amount REAL,
          category TEXT,
          note TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          deleted INTEGER DEFAULT 0,
          extra TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId TEXT UNIQUE,
          serverId TEXT,
          userId TEXT,
          title TEXT,
          target_amount REAL,
          saved_amount REAL,
          deadline TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          deleted INTEGER DEFAULT 0,
          extra TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE sync_queue(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId TEXT,
          op TEXT,
          entity TEXT,
          record TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE conflicts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId TEXT,
          entity TEXT,
          localRecord TEXT,
          serverRecord TEXT,
          reason TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE contributions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId TEXT UNIQUE,
          serverId TEXT,
          goalClientId TEXT,
          goalServerId TEXT,
          amount REAL,
          createdAt TEXT,
          updatedAt TEXT,
          deleted INTEGER DEFAULT 0,
          extra TEXT
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS contributions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId TEXT UNIQUE,
            serverId TEXT,
            goalClientId TEXT,
            goalServerId TEXT,
            amount REAL,
            createdAt TEXT,
            updatedAt TEXT,
            deleted INTEGER DEFAULT 0,
            extra TEXT
          )
        ''');
      }
    });
  }

  Future<int> insertTransactionLocal(Map<String, dynamic> tx) async {
    await init();
    final db = _db!;
    final data = Map<String, dynamic>.from(tx);
    // store extra as json text
    if (data['extra'] != null) data['extra'] = jsonEncode(data['extra']);
    return await db.insert('transactions', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    await init();
    final db = _db!;
    final rows = await db.query('transactions', where: 'deleted = ?', whereArgs: [0], orderBy: 'createdAt DESC');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      if (map['extra'] != null) {
        try {
          map['extra'] = jsonDecode(map['extra'] as String);
        } catch (_) {
          map['extra'] = null;
        }
      }
      return map;
    }).toList();
  }

  Future<int> insertGoalLocal(Map<String, dynamic> g) async {
    await init();
    final db = _db!;
    final data = Map<String, dynamic>.from(g);
    if (data['extra'] != null) data['extra'] = jsonEncode(data['extra']);
    return await db.insert('goals', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertContributionLocal(Map<String, dynamic> c) async {
    await init();
    final db = _db!;
    final data = Map<String, dynamic>.from(c);
    if (data['extra'] != null) data['extra'] = jsonEncode(data['extra']);
    try {
      return await db.insert('contributions', data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // If table missing, attempt to create it and retry once
      if (e is DatabaseException && e.toString().contains('no such table')) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS contributions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId TEXT UNIQUE,
            serverId TEXT,
            goalClientId TEXT,
            goalServerId TEXT,
            amount REAL,
            createdAt TEXT,
            updatedAt TEXT,
            deleted INTEGER DEFAULT 0,
            extra TEXT
          )
        ''');
        return await db.insert('contributions', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getContributions({String? goalClientId}) async {
    await init();
    final db = _db!;
    // ensure table exists (safe no-op if already present)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contributions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT UNIQUE,
        serverId TEXT,
        goalClientId TEXT,
        goalServerId TEXT,
        amount REAL,
        createdAt TEXT,
        updatedAt TEXT,
        deleted INTEGER DEFAULT 0,
        extra TEXT
      )
    ''');
    String? where;
    List<Object?>? whereArgs;
    if (goalClientId != null) {
      where = 'goalClientId = ? AND deleted = ?';
      whereArgs = [goalClientId, 0];
    }
    List<Map<String, Object?>> rows;
    try {
      rows = await db.query('contributions', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      if (map['extra'] != null) {
        try {
          map['extra'] = jsonDecode(map['extra'] as String);
        } catch (_) {
          map['extra'] = null;
        }
      }
      return map;
    }).toList();
  }

  Future<double> sumContributions({String? goalClientId}) async {
    await init();
    final db = _db!;
    // ensure table exists (safe no-op if already present)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contributions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT UNIQUE,
        serverId TEXT,
        goalClientId TEXT,
        goalServerId TEXT,
        amount REAL,
        createdAt TEXT,
        updatedAt TEXT,
        deleted INTEGER DEFAULT 0,
        extra TEXT
      )
    ''');
    try {
      if (goalClientId != null) {
        final res = await db.rawQuery('SELECT SUM(amount) as s FROM contributions WHERE goalClientId = ? AND deleted = 0', [goalClientId]);
        final val = res.first['s'] as num?;
        return val?.toDouble() ?? 0.0;
      }
      final res = await db.rawQuery('SELECT SUM(amount) as s FROM contributions WHERE deleted = 0');
      final val = res.first['s'] as num?;
      return val?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    await init();
    final db = _db!;
    final rows = await db.query('goals', where: 'deleted = ?', whereArgs: [0], orderBy: 'createdAt DESC');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      if (map['extra'] != null) {
        try {
          map['extra'] = jsonDecode(map['extra'] as String);
        } catch (_) {
          map['extra'] = null;
        }
      }
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>?> getGoalByClientId(String clientId) async {
    await init();
    final db = _db!;
    final rows = await db.query('goals', where: 'clientId = ?', whereArgs: [clientId]);
    if (rows.isEmpty) return null;
    final map = Map<String, dynamic>.from(rows.first);
    if (map['extra'] != null) {
      try {
        map['extra'] = jsonDecode(map['extra'] as String);
      } catch (_) {
        map['extra'] = null;
      }
    }
    return map;
  }

  Future<Map<String, dynamic>?> getGoalByServerId(String serverId) async {
    await init();
    final db = _db!;
    final rows = await db.query('goals', where: 'serverId = ?', whereArgs: [serverId]);
    if (rows.isEmpty) return null;
    final map = Map<String, dynamic>.from(rows.first);
    if (map['extra'] != null) {
      try {
        map['extra'] = jsonDecode(map['extra'] as String);
      } catch (_) {
        map['extra'] = null;
      }
    }
    return map;
  }

  Future<int> addSyncChange(String clientId, String op, String entity, Map<String, dynamic>? record) async {
    await init();
    final db = _db!;
    final rec = record == null ? null : jsonEncode(record);
    return await db.insert('sync_queue', {'clientId': clientId, 'op': op, 'entity': entity, 'record': rec, 'createdAt': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    await init();
    final db = _db!;
    final rows = await db.query('sync_queue', orderBy: 'id ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> removePendingChangeById(int id) async {
    await init();
    final db = _db!;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addConflict(String clientId, String entity, Map<String, dynamic>? local, Map<String, dynamic>? server, String? reason) async {
    await init();
    final db = _db!;
    final localJson = local == null ? null : jsonEncode(local);
    final serverJson = server == null ? null : jsonEncode(server);
    return await db.insert('conflicts', {'clientId': clientId, 'entity': entity, 'localRecord': localJson, 'serverRecord': serverJson, 'reason': reason, 'createdAt': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getConflicts() async {
    await init();
    final db = _db!;
    final rows = await db.query('conflicts', orderBy: 'createdAt DESC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> removeConflictById(int id) async {
    await init();
    final db = _db!;
    await db.delete('conflicts', where: 'id = ?', whereArgs: [id]);
  }

  /// Remove pending sync queue entries for a given clientId identifier.
  Future<int> removePendingChangesByClientId(String clientId) async {
    await init();
    final db = _db!;
    return await db.delete('sync_queue', where: 'clientId = ?', whereArgs: [clientId]);
  }

  Future<void> applyServerChange(String entity, Map<String, dynamic> row) async {
    await init();
    final db = _db!;
    final data = Map<String, dynamic>.from(row);

    // ensure extra is string
    if (data['extra'] != null && data['extra'] is Map) data['extra'] = jsonEncode(data['extra']);
    // sanitize and limit fields to known schema columns; convert booleans -> integers
    Map<String, dynamic> sanitize(Map<String, dynamic> src, List<String> allowed) {
      final out = <String, dynamic>{};
      for (final k in allowed) {
        if (!src.containsKey(k)) continue;
        var v = src[k];
        // convert bools to ints for sqlite
        if (v is bool) v = v ? 1 : 0;
        // ensure extra (Map) is string
        if (k == 'extra' && v is Map) v = jsonEncode(v);
        out[k] = v;
      }
      return out;
    }

    if (entity == 'transactions') {
      final allowed = ['serverId','clientId','userId','type','amount','category','note','createdAt','updatedAt','deleted','extra'];
      final sanitized = sanitize(data, allowed);
      if (sanitized.isEmpty) return;
      // upsert by clientId if present, else by serverId
      if (sanitized['clientId'] != null) {
        await db.insert('transactions', sanitized, conflictAlgorithm: ConflictAlgorithm.replace);
      } else if (sanitized['serverId'] != null) {
        final existing = await db.query('transactions', where: 'serverId = ?', whereArgs: [sanitized['serverId']]);
        if (existing.isNotEmpty) {
          await db.update('transactions', sanitized, where: 'serverId = ?', whereArgs: [sanitized['serverId']]);
        } else {
          await db.insert('transactions', sanitized);
        }
      }
    } else if (entity == 'goals') {
      final allowed = ['serverId','clientId','userId','title','target_amount','saved_amount','deadline','createdAt','updatedAt','deleted','extra'];
      final sanitized = sanitize(data, allowed);
      if (sanitized.isEmpty) return;
      if (sanitized['clientId'] != null) {
        await db.insert('goals', sanitized, conflictAlgorithm: ConflictAlgorithm.replace);
      } else if (sanitized['serverId'] != null) {
        final existing = await db.query('goals', where: 'serverId = ?', whereArgs: [sanitized['serverId']]);
        if (existing.isNotEmpty) {
          await db.update('goals', sanitized, where: 'serverId = ?', whereArgs: [sanitized['serverId']]);
        } else {
          await db.insert('goals', sanitized);
        }
      }
    }
  }

  Future<void> updateLocalRecordServerId(String table, String clientId, String serverId) async {
    await init();
    final db = _db!;
    await db.update(table, {'serverId': serverId}, where: 'clientId = ?', whereArgs: [clientId]);
  }

  Future<int> deleteGoalLocalByClientId(String clientId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('goals', {'deleted': 1, 'updatedAt': now}, where: 'clientId = ?', whereArgs: [clientId]);
  }

  Future<int> deleteTransactionLocalByClientId(String clientId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('transactions', {'deleted': 1, 'updatedAt': now}, where: 'clientId = ?', whereArgs: [clientId]);
  }

  Future<int> deleteTransactionLocalByServerId(String serverId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('transactions', {'deleted': 1, 'updatedAt': now}, where: 'serverId = ?', whereArgs: [serverId]);
  }

  Future<int> deleteGoalLocalByServerId(String serverId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('goals', {'deleted': 1, 'updatedAt': now}, where: 'serverId = ?', whereArgs: [serverId]);
  }

  /// Clear all local app data (for testing) by deleting rows from main tables
  /// and performing a VACUUM to reclaim space and reset autoincrement counters.
  Future<void> clearAllData() async {
    await init();
    final db = _db!;
    await db.transaction((txn) async {
      // Delete rows from tables; keep table schemas intact
      try {
        await txn.delete('sync_queue');
        await txn.delete('conflicts');
      } catch (_) {}
      try {
        await txn.delete('contributions');
      } catch (_) {}
      try {
        await txn.delete('transactions');
      } catch (_) {}
      try {
        await txn.delete('goals');
      } catch (_) {}
    });
    try {
      await db.execute('VACUUM');
    } catch (_) {}
  }

  // Mark a contribution as deleted by clientId
  Future<int> deleteContributionLocalByClientId(String clientId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('contributions', {'deleted': 1, 'updatedAt': now}, where: 'clientId = ?', whereArgs: [clientId]);
  }

  // Mark a contribution as deleted by serverId
  Future<int> deleteContributionLocalByServerId(String serverId) async {
    await init();
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    return await db.update('contributions', {'deleted': 1, 'updatedAt': now}, where: 'serverId = ?', whereArgs: [serverId]);
  }

  // Mark all contributions for a given goalClientId as deleted and return the list of affected contributions
  Future<List<Map<String, dynamic>>> deleteContributionsByGoalClientId(String goalClientId) async {
    await init();
    final db = _db!;
    // ensure table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contributions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId TEXT UNIQUE,
        serverId TEXT,
        goalClientId TEXT,
        goalServerId TEXT,
        amount REAL,
        createdAt TEXT,
        updatedAt TEXT,
        deleted INTEGER DEFAULT 0,
        extra TEXT
      )
    ''');
    final rows = await db.query('contributions', where: 'goalClientId = ? AND deleted = 0', whereArgs: [goalClientId]);
    final now = DateTime.now().toIso8601String();
    for (final r in rows) {
      final cid = r['clientId'] as String?;
      final sid = r['serverId'] as String?;
      if (cid != null) {
        await db.update('contributions', {'deleted': 1, 'updatedAt': now}, where: 'clientId = ?', whereArgs: [cid]);
      } else if (sid != null) {
        await db.update('contributions', {'deleted': 1, 'updatedAt': now}, where: 'serverId = ?', whereArgs: [sid]);
      }
    }
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}
