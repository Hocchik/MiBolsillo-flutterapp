import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/repository.dart';
import '../services/currency_service.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recent = [];

  Future<void> _loadStats() async {
    final s = await Repository().computeStats();
    // also load recent transactions (latest 5)
    final txs = await Repository().getLocalTransactions();
    final recent = txs.take(5).toList();
    if (mounted) setState(() { _stats = s; _recent = recent; });
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = Color(0xFF161616);

  // Compute totals from stats
  final bool hasData = _stats != null && ((_stats!['income'] as num?) != null || (_stats!['expense'] as num?) != null);
  final double totalIncome = (_stats?['income'] as num?)?.toDouble() ?? 0.0;
  final double totalExpense = (_stats?['expense'] as num?)?.toDouble() ?? 0.0;
  final double balance = (_stats?['balance'] as num?)?.toDouble() ?? 0.0;

  // Recent transactions loaded in state

    return ShellScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with optional reset button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                        // Actions: refresh stats + reset local data
                        Row(
                          children: [
                            // Currency selector small button
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final choice = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => SimpleDialog(
                                      title: const Text('Seleccionar moneda'),
                                      children: CurrencyService().supported.map((c) => SimpleDialogOption(
                                        onPressed: () => Navigator.of(ctx).pop(c),
                                        child: Text(c),
                                      )).toList(),
                                    ),
                                  );
                                  if (choice != null) {
                                    if (!mounted) return;
                                    await CurrencyService().setSelected(choice);
                                    if (!mounted) return;
                                    setState(() {});
                                    messenger.showSnackBar(SnackBar(content: Text('Moneda cambiada a $choice')));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(6)),
                                  child: Text(CurrencyService().selectedCurrency, style: const TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Actualizar',
                              icon: const Icon(Icons.refresh),
                              color: Colors.white,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await _loadStats();
                                  if (!mounted) return;
                                  messenger.showSnackBar(const SnackBar(content: Text('Datos actualizados')));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Error al actualizar: ${e.toString()}')));
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Reiniciar datos',
                              icon: const Icon(Icons.delete_sweep),
                              color: Colors.redAccent,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Reiniciar datos'),
                                    content: const Text('Esto borrará todas las transacciones, metas y aportes locales. ¿Continuar?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Borrar')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await Repository().resetAppData();
                                    if (!mounted) return;
                                    setState(() { _stats = null; _recent = []; });
                                    await _loadStats();
                                    messenger.showSnackBar(const SnackBar(content: Text('Datos reiniciados')));
                                  } catch (e) {
                                    messenger.showSnackBar(SnackBar(content: Text('Error al reiniciar: ${e.toString()}')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Balance card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Balance Total', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(fmtMoneyOrPlaceholder(hasData ? balance : null), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(children: [Text('Disponible', style: TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 6), Text(fmtMoneyOrPlaceholder(_stats?['available'] as double?), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]),
                            const SizedBox(width: 24),
                            Column(children: [Text('Separado', style: TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 6), Text(fmtMoneyOrPlaceholder(_stats?['separated'] as double?), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Small stats cards arranged like mock: two cards on top row, one below-left
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = 8.0;
                      // width for each top card (two columns)
                      final topCardWidth = (constraints.maxWidth - spacing) / 2;

                      Widget buildCard(IconData icon, Color iconColor, String label, String value) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: iconColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(label, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: topCardWidth, child: buildCard(Icons.trending_up, const Color(0xFF9AEF5E), 'Ingresos', fmtMoneyOrPlaceholder(hasData ? totalIncome : null))),
                              SizedBox(width: spacing),
                              SizedBox(width: topCardWidth, child: buildCard(Icons.trending_down, Colors.redAccent, 'Gastos', fmtMoneyOrPlaceholder(hasData ? totalExpense : null))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(width: topCardWidth, child: buildCard(Icons.account_balance_wallet, const Color(0xFF9AEF5E), 'Separado', fmtMoneyOrPlaceholder(_stats != null ? (_stats?['separated'] as num?)?.toDouble() : null))),
                              // keep the remaining space empty so the small card stays left-aligned
                              const Spacer(),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [Icon(Icons.flash_on, color: const Color(0xFFF1C232)), const SizedBox(width: 8), Text('Acciones Rápidas', style: TextStyle(color: Colors.white))]),
                            Text(' ', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AEF5E), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                onPressed: () => Navigator.pushNamed(context, '/add'),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: () => Navigator.pushNamed(context, '/coach'),
                              icon: const Icon(Icons.school),
                              label: const Text('Coach'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Progreso del Mes', style: TextStyle(color: Colors.white)), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(8)), child: Text(_stats != null ? fmtPercentOrPlaceholder((_stats?['savingsRate'] as num?)?.toDouble()) : '---', style: TextStyle(color: Colors.white)))]),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: (_stats?['savingsRate'] as num?)?.toDouble() ?? 0.0, backgroundColor: Colors.white10, color: const Color(0xFF9AEF5E)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Meta: ${hasData ? '\$5000' : '---'}', style: TextStyle(color: Colors.white70)), Text(hasData ? '\$3500' : '---', style: TextStyle(color: Colors.white))]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Recent transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Transacciones Recientes', style: TextStyle(color: Colors.white)), TextButton(onPressed: () => Navigator.pushNamed(context, '/transactions'), child: Text('Ver todas'))]),
                        const SizedBox(height: 8),
                        if (_recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text('No hay transacciones todavía', style: TextStyle(color: Colors.white54))),
                          )
                        else ...[
                          for (final t in _recent) ...[
                            _txTile(
                              t['category'] ?? t['title'] ?? '—',
                              t['note'] ?? '',
                              '${t['type'] == 'income' ? '+' : '-'}${fmtMoneyOrPlaceholder((t['amount'] as num?)?.toDouble())}',
                              t['type'] == 'income' ? Colors.green : Colors.red,
                              t['type'] == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                              (t['createdAt'] as String?) ?? (t['date'] as String?) ?? '',
                            ),
                            const SizedBox(height: 8),
                          ]
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _txTile(String title, String subtitle, String amount, Color amountColor, IconData icon, String date) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Color(0xFF1B1B1B), child: Icon(icon, color: Colors.white70)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 12))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text(date, style: TextStyle(color: Colors.white54, fontSize: 12))]),
        ],
      ),
    );
  }
}