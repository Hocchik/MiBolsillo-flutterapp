import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../utils/formatters.dart';
import '../services/repository.dart';
import '../services/currency_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  List<Map<String, dynamic>> _txs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Repository().computeStats();
    final txs = await Repository().getLocalTransactions();
    if (mounted) setState(() { _stats = s; _loading = false; });
    if (mounted) setState(() { _txs = txs; });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = const Color(0xFF161616);
    // show a loading indicator while repository stats are being computed
    if (_loading) {
      return ShellScaffold(
        currentIndex: 4,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final income = (_stats?['income'] as num?)?.toDouble();
    final expense = (_stats?['expense'] as num?)?.toDouble();

    return ShellScaffold(
      currentIndex: 4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Análisis Financiero', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                                SizedBox(height: 6),
                                Text('Comprende mejor tus patrones de gasto', style: TextStyle(color: Colors.white54), overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          ),
                          // Actions: refresh stats + reset local data
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Currency selector button
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    // show simple dialog to pick currency
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
                              // Refresh button: recompute stats
                              IconButton(
                                tooltip: 'Actualizar',
                                icon: const Icon(Icons.refresh),
                                color: Colors.white,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() { _loading = true; });
                                  try {
                                    await _load();
                                    if (!mounted) return;
                                    messenger.showSnackBar(const SnackBar(content: Text('Datos actualizados')));
                                  } catch (e) {
                                    messenger.showSnackBar(SnackBar(content: Text('Error al actualizar: ${e.toString()}')));
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // Reset button: clears local data
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
                                      setState(() { _stats = null; _loading = true; });
                                      await _load();
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: _smallStat('Total Ingresos', fmtMoneyOrPlaceholder(income), Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _smallStat('Total Gastos', fmtMoneyOrPlaceholder(expense), Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _smallStat('Promedio', fmtMoneyOrPlaceholder(null), Colors.amber)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tendencia Mensual', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 12),
                        SizedBox(height: 220, child: _barChart()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gastos por Categoría', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 12),
                        SizedBox(height: 200, child: _pieChart()),
                        const SizedBox(height: 12),
                        // Dynamic legend built from expense categories (matches pie chart)
                        ..._buildExpenseLegend(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        // compact row of three small cards driven by chart data
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Principal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(_stats?['coach']?['topCategory'] as String? ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Promedio (30d)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(fmtMoneyOrPlaceholder((_stats?['coach']?['avgDailyExpense'] as num?)?.toDouble()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Franja pico', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text((_stats?['coach']?['peakHour'] != null) ? '${(_stats?['coach']?['peakHour'] as int).toString().padLeft(2, '0')}:00' : '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // small explanation
                        const Text('Información resumida basada en los gráficos. Para recomendaciones detalladas visita la pestaña Coach.', style: TextStyle(color: Colors.white54, fontSize: 12)),
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

  static Widget _smallStat(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))]),
    );
  }

  

  // removed: replaced by compact legend rows generated by _buildExpenseLegend

  // Simple bar chart built from local transactions (_txs)
  Widget _barChart() {
    if (_txs.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text('---', style: TextStyle(color: Colors.white54))),
      );
    }

    final now = DateTime.now();
    // last 6 months (oldest -> newest)
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return m;
    });

    final incomePerMonth = List.filled(6, 0.0);
    final expensePerMonth = List.filled(6, 0.0);

    for (final t in _txs) {
      try {
        final d = DateTime.parse(t['createdAt'] as String);
        for (var i = 0; i < months.length; i++) {
          if (d.year == months[i].year && d.month == months[i].month) {
            final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
            if (t['type'] == 'income') {
              incomePerMonth[i] += amt;
            } else {
              expensePerMonth[i] += amt;
            }
          }
        }
      } catch (_) {}
    }

    final maxVal = <double>[...incomePerMonth, ...expensePerMonth].fold(0.0, (p, e) => e > p ? e : p);
    final colorsIncome = Colors.green[300]!;
    final colorsExpense = Colors.red[300]!;

    // sums for legend
    final totalIncome6 = incomePerMonth.fold(0.0, (p, e) => p + e);
    final totalExpense6 = expensePerMonth.fold(0.0, (p, e) => p + e);

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // leave more room for month labels and legend to avoid tiny overflows
          final maxHeight = (constraints.maxHeight - 80).clamp(0.0, constraints.maxHeight);
          return Column(
            children: [
              // legend
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  Row(children: [Container(width: 10, height: 10, color: colorsIncome), const SizedBox(width: 6), Text('Ingresos (${fmtMoneyOrPlaceholder(totalIncome6)})', style: const TextStyle(color: Colors.white54, fontSize: 12))]),
                  const SizedBox(width: 12),
                  Row(children: [Container(width: 10, height: 10, color: colorsExpense), const SizedBox(width: 6), Text('Gastos (${fmtMoneyOrPlaceholder(totalExpense6)})', style: const TextStyle(color: Colors.white54, fontSize: 12))]),
                ]),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (i) {
                    final inc = incomePerMonth[i];
                    final exp = expensePerMonth[i];
                    final incHraw = maxVal > 0 ? (inc / maxVal) * maxHeight : 0.0;
                    final expHraw = maxVal > 0 ? (exp / maxVal) * maxHeight : 0.0;
                    // clamp heights conservatively to avoid off-by-few-pixel overflows
                    final incH = incHraw.clamp(0.0, maxHeight * 0.8);
                    final expH = expHraw.clamp(0.0, maxHeight * 0.8);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // income bar (thin)
                            Container(height: incH, width: 12, decoration: BoxDecoration(color: colorsIncome, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 4),
                            // expense bar (thin)
                            Container(height: expH, width: 12, decoration: BoxDecoration(color: colorsExpense, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              // month labels: limit height and allow text to scale
              SizedBox(
                height: 18,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (i) {
                  final lbl = '${months[i].month}/${months[i].year % 100}';
                  return FittedBox(fit: BoxFit.scaleDown, child: Text(lbl, style: const TextStyle(color: Colors.white54, fontSize: 12)));
                })),
              ),
            ],
          );
        },
      ),
    );
  }

  // Simple pie chart showing expense breakdown by category using CustomPainter
  Widget _pieChart() {
    // Aggregate expenses by category for the last 30 days only
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final Map<String, double> sums = {};
    for (final t in _txs) {
      try {
        final d = DateTime.parse(t['createdAt'] as String);
        if (d.isBefore(cutoff)) continue;
      } catch (_) {
        // ignore parse errors and include the tx
      }
      if (t['type'] == 'income') continue;
      final cat = (t['category'] as String?) ?? (t['note'] as String?) ?? 'Otros';
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      sums[cat] = (sums[cat] ?? 0.0) + amt;
    }

    if (sums.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text('---', style: TextStyle(color: Colors.white54))),
      );
    }

    // sort categories by amount
    final entries = sums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    // top 4 categories
    final top = entries.take(4).toList();
    final other = entries.skip(4).fold<double>(0.0, (p, e) => p + e.value);
    final display = List<MapEntry<String, double>>.from(top);
    if (other > 0) display.add(MapEntry('Otros', other));

    final total = display.fold(0.0, (p, e) => p + e.value);
    final colors = [Colors.green, Colors.amber, Colors.red, Colors.blue, Colors.grey];

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _PieChartPainter(display.map((e) => e.value / (total == 0 ? 1 : total)).toList(), colors),
          ),
        ),
      ),
    );
  }

  // Build legend widgets for expenses (used under the pie chart)
  List<Widget> _buildExpenseLegend() {
    // Build legend from expenses in the last 30 days only
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final Map<String, double> sums = {};
    for (final t in _txs) {
      try {
        final d = DateTime.parse(t['createdAt'] as String);
        if (d.isBefore(cutoff)) continue;
      } catch (_) {}
      if (t['type'] == 'income') continue;
      final cat = (t['category'] as String?) ?? (t['note'] as String?) ?? 'Otros';
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      sums[cat] = (sums[cat] ?? 0.0) + amt;
    }

    if (sums.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Center(child: Text('No hay gastos registrados', style: TextStyle(color: Colors.white54))),
        )
      ];
    }

    final entries = sums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(4).toList();
    final other = entries.skip(4).fold<double>(0.0, (p, e) => p + e.value);
    final display = List<MapEntry<String, double>>.from(top);
    if (other > 0) display.add(MapEntry('Otros', other));

    final total = display.fold(0.0, (p, e) => p + e.value);
    final colors = [Colors.green, Colors.amber, Colors.red, Colors.blue, Colors.grey];

    // Build compact rows matching the mock: dot, label, amount and percent badge
    return List<Widget>.generate(display.length, (i) {
      final label = display[i].key;
      final amt = display[i].value;
      final pct = total > 0 ? (amt / total) : 0.0;
      final color = colors[i % colors.length];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 8),
              Text(fmtMoneyOrPlaceholder(amt), style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)), child: Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70)))
            ],
          ),
        ),
      );
    });
  }

}

class _PieChartPainter extends CustomPainter {
  final List<double> parts;
  final List<Color> palette;
  _PieChartPainter(this.parts, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    double start = -90.0 * (3.1415926 / 180.0);
    for (var i = 0; i < parts.length; i++) {
      final sweep = (parts[i] * 360.0) * (3.1415926 / 180.0);
      paint.color = palette[i % palette.length];
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
