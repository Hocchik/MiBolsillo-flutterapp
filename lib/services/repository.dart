import 'package:uuid/uuid.dart';

import 'app_config.dart';
import 'local_db.dart';
import 'sync_manager.dart';

/// Repository coordinates LocalDb <-> ApiService and provides high-level methods
/// for screens to create/read transactions and goals. It ensures local persistence
/// and enqueues sync operations, attempting immediate server calls when possible.
class Repository {
  static final Repository _instance = Repository._internal();
  factory Repository() => _instance;
  Repository._internal();

  final _uuid = const Uuid();
  final _db = LocalDb();
  final _api = AppConfig.apiInstance();

  /// Initialize local DB and start sync manager if needed.
  Future<void> init() async {
    await _db.init();
    SyncManager().start();
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> tx) async {
    final clientId = 'c_tx_${_uuid.v4()}';
    final now = DateTime.now().toIso8601String();
    final record = <String, dynamic>{
      'clientId': clientId,
      'type': tx['type'],
      'amount': tx['amount'],
      'category': tx['category'],
      'note': tx['note'],
      'createdAt': tx['createdAt'] ?? now,
      'updatedAt': tx['updatedAt'] ?? now,
      'extra': tx['extra'],
    };

    // Persist locally
    await _db.insertTransactionLocal(record);

    // Enqueue for sync
    await _db.addSyncChange(clientId, 'create', 'transactions', record);

    // Try immediate server send, but don't fail if offline
    try {
      final resp = await _api.postTransaction(record);
      // Update local row with serverId if returned
      if (resp['serverId'] != null) {
        await _db.updateLocalRecordServerId('transactions', clientId, resp['serverId']);
      }
      return resp;
    } catch (_) {
      // Return the local record as fallback
      return record;
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> g) async {
    // Validate constraints: unique title and max 5 active goals
    final existingGoals = await getLocalGoals();
    final activeCount = existingGoals.length;
    final titleCandidate = (g['title'] as String?)?.trim() ?? '';
    if (titleCandidate.isNotEmpty) {
      final exists = existingGoals.any((gg) => (gg['title'] as String?)?.toLowerCase() == titleCandidate.toLowerCase());
      if (exists) throw Exception('Ya existe una meta con ese nombre');
    }
    if (activeCount >= 5) throw Exception('Solo puedes tener hasta 5 metas activas');

    final clientId = 'c_goal_${_uuid.v4()}';
    final now = DateTime.now().toIso8601String();
    final record = <String, dynamic>{
      'clientId': clientId,
      'title': g['title'],
      'target_amount': g['target_amount'] ?? g['target'] ?? 0,
      'saved_amount': g['saved_amount'] ?? g['saved'] ?? 0,
      'deadline': g['deadline'],
      'createdAt': g['createdAt'] ?? now,
      'updatedAt': g['updatedAt'] ?? now,
      'extra': g['extra'],
    };

    await _db.insertGoalLocal(record);
    await _db.addSyncChange(clientId, 'create', 'goals', record);

    try {
      final resp = await _api.postGoal(record);
      if (resp['serverId'] != null) {
        await _db.updateLocalRecordServerId('goals', clientId, resp['serverId']);
      }
      return resp;
    } catch (_) {
      return record;
    }
  }

  /// Delete a goal (soft-delete) and its contributions. Returns a context
  /// map containing the original goal record, affected contributions and the
  /// list of queued clientIds added to the sync queue so the UI can offer undo.
  Future<Map<String, dynamic>> deleteGoal(String id) async {
    // id may be clientId or serverId — try clientId first
    var local = await _db.getGoalByClientId(id);
    local ??= await _db.getGoalByServerId(id);
    if (local == null) throw Exception('Meta no encontrada');

    final clientId = local['clientId'] as String?;
    final serverId = local['serverId'] as String?;

    final Map<String, dynamic> originalGoal = Map<String, dynamic>.from(local);
    final List<Map<String, dynamic>> affectedContribs = [];
    final List<String> queuedClientIds = [];

    if (clientId != null) {
      // collect contributions, mark them deleted and enqueue delete ops
      final contribs = await _db.deleteContributionsByGoalClientId(clientId);
      affectedContribs.addAll(contribs);
      for (final c in contribs) {
        final cClientId = c['clientId'] as String?;
        final cServerId = c['serverId'] as String?;
        if (cClientId != null) {
          await _db.addSyncChange(cClientId, 'delete', 'contributions', {'clientId': cClientId});
          queuedClientIds.add(cClientId);
        } else if (cServerId != null) {
          final pseudo = 's_contrib_$cServerId';
          await _db.addSyncChange(pseudo, 'delete', 'contributions', {'serverId': cServerId});
          queuedClientIds.add(pseudo);
        }
      }
      // mark goal deleted and enqueue its delete
      await _db.deleteGoalLocalByClientId(clientId);
      await _db.addSyncChange(clientId, 'delete', 'goals', {'clientId': clientId});
      queuedClientIds.add(clientId);
    } else if (serverId != null) {
      // find contributions referencing this serverId
      final contribRows = await _db.getContributions();
      final affected = contribRows.where((c) => (c['goalServerId'] as String?) == serverId).toList();
      for (final c in affected) {
        final cClientId = c['clientId'] as String?;
        final cServerId = c['serverId'] as String?;
        if (cClientId != null) {
          await _db.deleteContributionLocalByClientId(cClientId);
          await _db.addSyncChange(cClientId, 'delete', 'contributions', {'clientId': cClientId});
          queuedClientIds.add(cClientId);
        } else if (cServerId != null) {
          await _db.deleteContributionLocalByServerId(cServerId);
          final pseudo = 's_contrib_$cServerId';
          await _db.addSyncChange(pseudo, 'delete', 'contributions', {'serverId': cServerId});
          queuedClientIds.add(pseudo);
        }
        affectedContribs.add(Map<String, dynamic>.from(c));
      }
      await _db.deleteGoalLocalByServerId(serverId);
      final clientIdForQueue = 's_goal_$serverId';
      await _db.addSyncChange(clientIdForQueue, 'delete', 'goals', {'serverId': serverId});
      queuedClientIds.add(clientIdForQueue);
    }

    // best-effort: attempt server delete if serverId present
    try {
      if (serverId != null && serverId.isNotEmpty) {
        await _api.deleteGoal(serverId);
      }
    } catch (_) {}

    return {
      'goal': originalGoal,
      'contributions': affectedContribs,
      'queuedClientIds': queuedClientIds,
    };
  }

  /// Undo a previous delete operation using the provided context: original
  /// goal record, list of contribution records, and queued clientId identifiers
  /// that were added to the sync queue. This will restore local rows and
  /// remove the pending delete items from the queue.
  Future<void> undoDeleteGoal(Map<String, dynamic>? goalRecord, List<Map<String, dynamic>> contributions, List<String> queuedClientIds) async {
    if (goalRecord != null) {
      final restored = Map<String, dynamic>.from(goalRecord);
      restored['deleted'] = 0;
      restored['updatedAt'] = DateTime.now().toIso8601String();
      await _db.insertGoalLocal(restored);
    }
    for (final c in contributions) {
      final rc = Map<String, dynamic>.from(c);
      rc['deleted'] = 0;
      rc['updatedAt'] = DateTime.now().toIso8601String();
      await _db.insertContributionLocal(rc);
    }
    // remove queued deletes by clientId placeholder
    for (final cid in queuedClientIds) {
      try {
        await _db.removePendingChangesByClientId(cid);
      } catch (_) {}
    }
  }

  /// Reset all local app data (useful for testing from zero)
  Future<void> resetAppData() async {
    await _db.clearAllData();
  }

  Future<List<Map<String, dynamic>>> getLocalTransactions() async => await _db.getTransactions();
  Future<List<Map<String, dynamic>>> getLocalGoals() async => await _db.getGoals();

  Future<List<Map<String, dynamic>>> getContributionsForGoal(String goalClientId) async {
    return await _db.getContributions(goalClientId: goalClientId);
  }

  Future<double> getSeparatedForGoal(String goalClientId) async {
    return await _db.sumContributions(goalClientId: goalClientId);
  }

  /// Contribute an amount to a goal identified by clientId.
  /// Updates local saved_amount, enqueues a sync update and tries to send to server.
  Future<Map<String, dynamic>> contributeToGoal(String clientId, double amount) async {
    // fetch existing local goal by clientId first, then by serverId if not found
    var local = await _db.getGoalByClientId(clientId) ?? await _db.getGoalByServerId(clientId);
    if (local == null) {
      throw Exception('Goal not found locally');
    }

    final now = DateTime.now().toIso8601String();
    final saved = (local['saved_amount'] as num?)?.toDouble() ?? 0.0;
    final newSaved = saved + amount;

    final updated = Map<String, dynamic>.from(local);
    updated['saved_amount'] = newSaved;
    updated['updatedAt'] = now;

    // Persist updated goal locally (replace by clientId)
    await _db.insertGoalLocal(updated);

    // Create a contribution record (separated money) and persist locally
    final contribClientId = 'c_contrib_${_uuid.v4()}';
    final contrib = {
      'clientId': contribClientId,
      'goalClientId': local['clientId'] as String?,
      'goalServerId': local['serverId'] as String?,
      'amount': amount,
      'createdAt': now,
      'updatedAt': now,
      'extra': null,
    };
    await _db.insertContributionLocal(contrib);
    // Enqueue contribution for sync
    await _db.addSyncChange(contribClientId, 'create', 'contributions', contrib);

    // Enqueue goal update for sync
    await _db.addSyncChange(local['clientId'] as String, 'update', 'goals', updated);

    // Try immediate server update for goal if we have serverId (best-effort)
    try {
      final serverId = updated['serverId'] as String?;
      if (serverId != null && serverId.isNotEmpty) {
        final resp = await _api.putGoal(serverId, updated);
        if (resp['serverId'] != null) {
          await _db.updateLocalRecordServerId('goals', local['clientId'] as String, resp['serverId'] as String);
        }
        // Note: we don't attempt to POST contribution to server here because there's no endpoint yet.
        return resp;
      }
    } catch (_) {
      // ignore network errors — SyncManager will process queue
    }

    return updated;
  }

  /// Compute basic stats from transactions and goals
  Future<Map<String, dynamic>> computeStats() async {
    final txs = await getLocalTransactions();
    double income = 0.0;
    double expense = 0.0;
    for (final t in txs) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'income') {
        income += amt;
      } else {
        expense += amt;
      }
    }
    final balance = income - expense;

    // Simple monthly aggregation (last 30 days)
    final now = DateTime.now();
    final last30 = txs.where((t) {
      try {
        final d = DateTime.parse(t['createdAt'] as String);
        return now.difference(d).inDays <= 30;
      } catch (_) {
        return false;
      }
    }).toList();

    double monthIncome = 0.0, monthExpense = 0.0;
    for (final t in last30) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'income') {
        monthIncome += amt;
      } else {
        monthExpense += amt;
      }
    }

    // Goals progress
    final goals = await getLocalGoals();
    final goalsProgress = goals.map((g) {
      final target = (g['target_amount'] as num?)?.toDouble() ?? 0.0;
      final saved = (g['saved_amount'] as num?)?.toDouble() ?? 0.0;
      final pct = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
      return {'title': g['title'], 'pct': pct, 'saved': saved, 'target': target};
    }).toList();

    // Separated money (sum of contributions) — treat contributions as "good expenses" for analysis
    final separated = await _db.sumContributions();
    // Available money = income - expense - separated
    final available = income - expense - separated;

    // Coach simple heuristics
    final savingsRate = income > 0 ? (income - expense) / income : 0.0;
    final savingsRateIncludingSeparated = income > 0 ? (income - expense - separated) / income : 0.0;
    String coachSummary;
    if (savingsRate >= 0.3) {
      coachSummary = 'Excelente — estás ahorrando bien.';
    } else if (savingsRate >= 0.1) {
      coachSummary = 'Bien — hay espacio para mejorar tu ahorro.';
    } else {
      coachSummary = 'Atención — intenta reducir gastos o aumentar ingresos.';
    }

    return {
      'income': income,
      'expense': expense,
      'balance': balance,
      'separated': separated,
      'available': available,
      'totalExpenseWithContrib': expense + separated,
      'monthIncome': monthIncome,
      'monthExpense': monthExpense,
      'goalsProgress': goalsProgress,
      'savingsRate': savingsRate,
      'savingsRateIncludingSeparated': savingsRateIncludingSeparated,
      'coachSummary': coachSummary,
    };
  }
}
