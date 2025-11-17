import 'dart:convert';

import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/local_db.dart';
// formatters not needed here yet

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({super.key});

  @override
  State<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  final _db = LocalDb();
  List<Map<String, dynamic>> _conflicts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _db.getConflicts();
    if (mounted) setState(() { _conflicts = c; _loading = false; });
  }

  Future<void> _keepServer(Map<String, dynamic> conflict) async {
    // apply server record and remove conflict
    final serverJson = conflict['serverRecord'] as String?;
    if (serverJson != null) {
      try {
        final server = jsonDecode(serverJson) as Map<String, dynamic>;
        await _db.applyServerChange(conflict['entity'] as String? ?? 'transactions', server);
      } catch (_) {}
    }
    await _db.removeConflictById(conflict['id'] as int);
    await _load();
  }

  Future<void> _keepLocal(Map<String, dynamic> conflict) async {
    // re-enqueue local record to sync queue with op=update
    final localJson = conflict['localRecord'] as String?;
    if (localJson != null) {
      try {
        final local = jsonDecode(localJson) as Map<String, dynamic>;
        final clientId = conflict['clientId'] as String? ?? local['clientId'] as String? ?? '';
        await _db.addSyncChange(clientId, 'update', conflict['entity'] as String? ?? 'transactions', local);
      } catch (_) {}
    }
    await _db.removeConflictById(conflict['id'] as int);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      currentIndex: 0,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Conflictos de Sincronización', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _conflicts.isEmpty)
              const Expanded(child: Center(child: Text('No hay conflictos pendientes', style: TextStyle(color: Colors.white54)))),
            if (!_loading && _conflicts.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _conflicts.length,
                  itemBuilder: (context, i) {
                    final c = _conflicts[i];
                    final local = c['localRecord'] != null ? _prettyJson(c['localRecord']) : '—';
                    final server = c['serverRecord'] != null ? _prettyJson(c['serverRecord']) : '—';
                    return Card(
                      color: const Color(0xFF121212),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entidad: ${c['entity'] ?? 'transactions'}', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text('Local:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            Text(local, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text('Servidor:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            Text(server, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              ElevatedButton(onPressed: () => _keepLocal(c), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AEF5E), foregroundColor: Colors.black), child: const Text('Mantener local')),
                              const SizedBox(width: 8),
                              OutlinedButton(onPressed: () => _keepServer(c), style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Usar servidor')),
                            ])
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prettyJson(String raw) {
    try {
      final m = jsonDecode(raw);
      final enc = JsonEncoder.withIndent('  ');
      return enc.convert(m);
    } catch (_) {
      return raw;
    }
  }
}
