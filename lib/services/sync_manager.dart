import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_db.dart';
import 'app_config.dart';
import 'auth_service.dart';

/// SyncManager listens to connectivity changes and performs a POST /sync when online.
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final _connectivity = Connectivity();
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _connectivity.onConnectivityChanged.listen((dynamic result) async {
      ConnectivityResult status = ConnectivityResult.none;
      try {
        if (result is List && result.isNotEmpty) {
          status = result[0] as ConnectivityResult;
        } else if (result is ConnectivityResult) {
          status = result;
        }
      } catch (_) {
        status = ConnectivityResult.none;
      }

      if (status != ConnectivityResult.none) {
        await _trySync();
      }
    });
  }

  Future<void> _trySync() async {
    // Only sync if logged in
    final auth = AuthService();
    final loggedIn = await auth.isLoggedIn();
    if (!loggedIn) return;

    final api = AppConfig.apiInstance();
    final db = LocalDb();
    final pending = await db.getPendingChanges();
    if (pending.isEmpty) return;

    final clientChanges = pending.map((p) {
      final rec = p['record'] == null ? null : jsonDecode(p['record'] as String);
      return {
        'clientId': p['clientId'],
        'op': p['op'],
        'entity': p['entity'] ?? 'transactions',
        'record': rec,
      };
    }).toList();

    try {
      final res = await api.postSync({'clientChanges': clientChanges});

      // Process accepted
      final accepted = (res['accepted'] as List<dynamic>?) ?? [];
      final acceptedClientIds = <String>{};
      for (final a in accepted) {
        final clientId = a['clientId'] as String?;
        final serverId = a['serverId'] as String?;
        final status = a['status'] as String?;
        if (status == 'ok' && clientId != null && serverId != null) {
          acceptedClientIds.add(clientId);
          // update local record serverId for both tables
          await db.updateLocalRecordServerId('transactions', clientId, serverId).catchError((_) {});
          await db.updateLocalRecordServerId('goals', clientId, serverId).catchError((_) {});
        }
      }

      // Remove processed items from queue only for accepted clientIds
      for (final p in pending) {
        final cid = p['clientId'] as String?;
        if (cid != null && acceptedClientIds.contains(cid)) {
          await db.removePendingChangeById(p['id'] as int);
        }
      }

      // Apply serverChanges
      final serverChanges = (res['serverChanges'] as List<dynamic>?) ?? [];
      for (final sc in serverChanges) {
        final entity = sc['entity'] as String? ?? 'transactions';
        final row = sc['row'] as Map<String, dynamic>? ?? sc as Map<String, dynamic>;
        await db.applyServerChange(entity, row);
      }

      // Handle conflicts: persist them to local DB so user can resolve later
      final conflicts = (res['conflicts'] as List<dynamic>?) ?? [];
      for (final c in conflicts) {
        try {
          final clientId = c['clientId'] as String? ?? c['record']?['clientId'] as String?;
          final entity = c['entity'] as String? ?? 'transactions';
          final localRec = c['local'] as Map<String, dynamic>? ?? c['record'] as Map<String, dynamic>?;
          final serverRec = c['server'] as Map<String, dynamic>?;
          final reason = c['reason'] as String?;
          await db.addConflict(clientId ?? '', entity, localRec, serverRec, reason);
        } catch (_) {}
      }
    } catch (e) {
      // Sync failed; will retry on next connectivity change
    }
  }
}
