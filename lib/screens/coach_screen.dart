import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/repository.dart';
import '../utils/formatters.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Repository().computeStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = const Color(0xFF161616);
    final double? healthIndex = (_stats?['savingsRate'] as num?)?.toDouble();
    final double? balance = (_stats?['balance'] as num?)?.toDouble();
    // coachSummary removed: recommendations rendered from _stats['coach']['recommendations']
    return ShellScaffold(
      currentIndex: 2,
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFF7BB32F)])),
                    child: Column(children: [
                      const Icon(Icons.psychology, size: 34, color: Colors.black),
                      const SizedBox(height: 8),
                      const Text('Tu Coach Financiero', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Consejos prácticos y basados en tus datos locales.', style: TextStyle(color: Colors.black87), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Crear meta'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.swap_horiz), label: const Text('Filtrar'), style: OutlinedButton.styleFrom(foregroundColor: Colors.black)),
                      ])
                    ]),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Salud Financiera', style: TextStyle(color: Colors.white)),
                        Chip(label: Text(_stats != null ? (healthIndex != null ? fmtPercentOrPlaceholder(healthIndex) : '—') : '—', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2E7D32)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fmtPercentOrPlaceholder(healthIndex), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: (healthIndex ?? 0.0).clamp(0.0, 1.0), color: const Color(0xFF9AEF5E), backgroundColor: Colors.white10),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Balance', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text(fmtMoneyOrPlaceholder(balance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _metricBox('Meta principal', _stats?['coach']?['topCategory'] as String? ?? '—')),
                        const SizedBox(width: 8),
                        Expanded(child: _metricBox('Promedio (30d)', fmtMoneyOrPlaceholder((_stats?['coach']?['avgDailyExpense'] as num?)?.toDouble()))),
                        const SizedBox(width: 8),
                        Expanded(child: _metricBox('Franja pico', (_stats?['coach']?['peakHour'] != null) ? '${(_stats?['coach']?['peakHour'] as int).toString().padLeft(2, '0')}:00' : '—')),
                      ]),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Recomendaciones', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 12),
                      // coach recommendations list
                      if ((_stats?['coach']?['recommendations'] as List<dynamic>?)?.isNotEmpty != true)
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0F2E12), borderRadius: BorderRadius.circular(8)), child: const Text('No hay recomendaciones por el momento. Añade transacciones para obtener ideas.', style: TextStyle(color: Colors.white70)))
                      else
                        Column(children: [
                          for (final r in ((_stats?['coach']?['recommendations'] as List<dynamic>?) ?? []))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Container(
                                decoration: BoxDecoration(color: const Color(0xFF0F2E12), borderRadius: BorderRadius.circular(8)),
                                child: ListTile(
                                  leading: const CircleAvatar(backgroundColor: Color(0xFF2E7D32), child: Icon(Icons.check, color: Colors.white, size: 18)),
                                  title: Text(r.toString(), style: const TextStyle(color: Colors.white)),
                                  dense: true,
                                  trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white70)),
                                ),
                              ),
                            ),
                        ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Crear meta de ahorro'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AEF5E), foregroundColor: Colors.black))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.list), label: const Text('Ver transacciones'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white70))),
                      ])
                    ]),
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

  Widget _metricBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0E1A12), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}