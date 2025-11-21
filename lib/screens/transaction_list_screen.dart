import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/repository.dart';
import '../utils/formatters.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // refresh when repository signals data changes
    Repository().dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    Repository().dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await Repository().getLocalTransactions();
    if (mounted) setState(() { _txs = items; _loading = false; });
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text('Transacciones', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_txs.isEmpty
                      ? const Center(child: Text('No hay transacciones registradas', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: _txs.length,
                          itemBuilder: (context, index) {
                            final t = _txs[index];
                            final amount = (t['amount'] as num?)?.toDouble();
                            final date = (t['createdAt'] as String?) ?? t['date'] as String?;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  CircleAvatar(backgroundColor: const Color(0xFF1B1B1B), child: Icon(t['type'] == 'income' ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white70)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['category'] ?? 'Transacción', style: const TextStyle(color: Colors.white)), const SizedBox(height: 4), Text(t['note'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12))])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${t['type'] == 'income' ? '+' : '-'}${fmtMoneyOrPlaceholder(amount)}', style: TextStyle(color: t['type'] == 'income' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(fmtDateOrPlaceholder(date), style: const TextStyle(color: Colors.white54, fontSize: 12))]),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white54),
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Eliminar transacción'),
                                          content: const Text('¿Seguro que desea eliminar esta transacción?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;
                                      try {
                                        final id = (t['clientId'] as String?) ?? (t['serverId'] as String?);
                                        final ctx = await Repository().deleteTransaction(id ?? '');
                                        if (!mounted) return;
                                        // remove from UI
                                        setState(() { _txs.removeAt(index); });
                                        messenger.showSnackBar(SnackBar(
                                          content: const Text('Transacción eliminada'),
                                          action: SnackBarAction(label: 'Deshacer', onPressed: () async {
                                            try {
                                              await Repository().undoDeleteTransaction(ctx['transaction'] as Map<String, dynamic>?, List<String>.from(ctx['queuedClientIds'] ?? []));
                                              await _load();
                                            } catch (_) {}
                                          }),
                                        ));
                                      } catch (e) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.toString()}')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
