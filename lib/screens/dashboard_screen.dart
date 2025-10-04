import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final cardBg = Color(0xFF161616);
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
                      children: const [
                        Text('Balance Total', style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 8),
                        Text('\$2850', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('↗ Ingresos', style: TextStyle(color: Colors.black54)),
                            SizedBox(width: 20),
                            Text('↘ Gastos', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Small stats cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [Icon(Icons.trending_up, color: const Color(0xFF9AEF5E)), const SizedBox(width: 8), Text('Ingresos', style: TextStyle(color: Colors.white70))],
                              ),
                              const SizedBox(height: 8),
                              const Text('\$3500', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [Icon(Icons.trending_down, color: Colors.redAccent), const SizedBox(width: 8), Text('Gastos', style: TextStyle(color: Colors.white70))],
                              ),
                              const SizedBox(height: 8),
                              const Text('\$650', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Progreso del Mes', style: TextStyle(color: Colors.white)), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(8)), child: Text('70%', style: TextStyle(color: Colors.white)))]),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: 0.7, backgroundColor: Colors.white10, color: const Color(0xFF9AEF5E)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Meta: \$5000', style: TextStyle(color: Colors.white70)), Text('\$3500', style: TextStyle(color: Colors.white))]),
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
                        _txTile('Salario', 'Salario mensual', '+\$3000', Colors.green, Icons.arrow_upward, '2024-12-01'),
                        const SizedBox(height: 8),
                        _txTile('Comida', 'Supermercado semanal', '-\$450', Colors.red, Icons.arrow_downward, '2024-12-15'),
                        const SizedBox(height: 8),
                        _txTile('Transporte', 'Combustible', '-\$80', Colors.red, Icons.arrow_downward, '2024-12-20'),
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