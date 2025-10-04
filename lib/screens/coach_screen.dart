import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardBg = const Color(0xFF161616);
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
                          children: const [
                            Text('Salud Financiera', style: TextStyle(color: Colors.white)),
                            Chip(label: Text('Excelente', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF2E7D32)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('100', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(value: 1.0, color: Color(0xFF9AEF5E), backgroundColor: Colors.white10),
                        const SizedBox(height: 8),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tasa de Ahorro', style: TextStyle(color: Colors.white70)), Text('Balance \$2850', style: TextStyle(color: Colors.white))]),
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
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('¡Excelente trabajo!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Estás ahorrando un 81% de tus ingresos. Considera invertir parte de estos ahorros para hacerlos crecer.', style: TextStyle(color: Colors.white70)),
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