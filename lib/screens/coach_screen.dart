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
    final String coachSummary = (_stats?['coachSummary'] as String?) ?? '---';
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFF7BB32F)]),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.psychology, size: 34, color: Colors.black),
                        SizedBox(height: 8),
                        Text('Tu Coach Financiero IA', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('¡Hola! He analizado tus finanzas y tengo consejos personalizados para ti.', style: TextStyle(color: Colors.black87), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Salud Financiera', style: TextStyle(color: Colors.white)),
                            Chip(label: Text(_stats != null ? (healthIndex != null ? fmtPercentOrPlaceholder(healthIndex) : '—') : '—', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2E7D32)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(fmtPercentOrPlaceholder(healthIndex), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: healthIndex ?? 0.0, color: const Color(0xFF9AEF5E), backgroundColor: Colors.white10),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tasa de Ahorro', style: TextStyle(color: Colors.white70)), Text(fmtMoneyOrPlaceholder(balance), style: const TextStyle(color: Colors.white))]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Consejos Personalizados', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0F2E12), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(coachSummary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Revisa las acciones recomendadas para mejorar tu salud financiera.', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Acciones Recomendadas', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AEF5E), foregroundColor: Colors.black),
                          child: const Text('Crear meta de ahorro'),
                        ),
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
}