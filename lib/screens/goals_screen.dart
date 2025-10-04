import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';

class Goal {
  String title;
  double target;
  double saved;
  DateTime? deadline;
  IconData icon;

  Goal({required this.title, required this.target, this.saved = 0, this.deadline, required this.icon});

  int get progressPercent {
    if (target <= 0) return 0;
    final pct = (saved / target * 100).clamp(0, 100);
    return pct.round();
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [
    Goal(title: 'Fondo de Emergencia', target: 10000, saved: 3500, deadline: DateTime.now().subtract(Duration(days: 2)), icon: Icons.album),
    Goal(title: 'Vacaciones en Europa', target: 8000, saved: 2400, deadline: DateTime.now().add(Duration(days: 58)), icon: Icons.flight),
  ];

  void _openCreateGoal() async {
    final newGoal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateGoalCard(),
      ),
    );

    if (newGoal != null) {
      setState(() => _goals.insert(0, newGoal));
    }
  }

  Widget _goalCard(Goal g) {
    final cardBg = const Color(0xFF1A1A1A);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.deepOrange.shade800.withOpacity(0.2), child: Icon(g.icon, color: Colors.yellow[700])),
              const SizedBox(width: 12),
              Expanded(child: Text(g.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: Text('${g.progressPercent}%', style: const TextStyle(color: Colors.yellow))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: (g.target == 0) ? 0 : g.saved / g.target, minHeight: 10, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('\$${g.saved.toStringAsFixed(0)} / \$${g.target.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)), Text(g.deadline == null ? '' : _deadlineLabel(g.deadline!), style: const TextStyle(color: Colors.yellow))]),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.black), child: const Text('Aportar')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Ver detalles')),
          ])
        ],
      ),
    );
  }

  String _deadlineLabel(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now).inDays;
    if (diff < 0) return 'Meta vencida';
    return '$diff días restantes';
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      currentIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const CircleAvatar(radius: 32, backgroundColor: Colors.transparent, child: Icon(Icons.adjust, size: 48, color: Colors.yellow)),
            const SizedBox(height: 12),
            const Text('Mis Metas de Ahorro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Convierte tus sueños en objetivos alcanzables', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 18),

            // Create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: _openCreateGoal,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFFF7D35C), Color(0xFF9AEF5E)])),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add, color: Colors.black), SizedBox(width: 8), Text('Crear Nueva Meta', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]),
                ),
              ),
            ),

            const SizedBox(height: 18),

            ..._goals.map(_goalCard).toList(),

            const SizedBox(height: 40),
            // Encouragement card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF2F4F2F), Color(0xFF21321A)])),
                child: Column(children: const [Icon(Icons.emoji_events, color: Colors.yellow), SizedBox(height: 8), Text('¡Sigue así!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Con disciplina y constancia, puedes lograr cualquier meta financiera que te propongas.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)]),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _CreateGoalCard extends StatefulWidget {
  @override
  State<_CreateGoalCard> createState() => _CreateGoalCardState();
}

class _CreateGoalCardState extends State<_CreateGoalCard> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime? _deadline;
  int _selectedIcon = 0;

  final _icons = [Icons.adjust, Icons.directions_car, Icons.home, Icons.flight, Icons.card_giftcard];
  final _iconLabels = ['General', 'Auto', 'Casa', 'Viaje', 'Regalo'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 10));
    if (picked != null) setState(() => _deadline = picked);
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '')) ?? 0;
    final g = Goal(title: title.isEmpty ? 'Nueva Meta' : title, target: target, saved: 0, deadline: _deadline, icon: _icons[_selectedIcon]);
    Navigator.of(context).pop(g);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = const Color(0xFF1A1A1A);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nueva Meta', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(controller: _titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre de la meta', hintText: 'Ej: Fondo de emergencia', filled: true, fillColor: Color(0xFF0D0D0D)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Cantidad objetivo', filled: true, fillColor: Color(0xFF0D0D0D)), validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '')) == null) ? 'Ingresa un número válido' : null),
              const SizedBox(height: 8),
              GestureDetector(onTap: _pickDate, child: AbsorbPointer(child: TextFormField(controller: TextEditingController(text: _deadline == null ? '' : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'), decoration: const InputDecoration(labelText: 'Fecha límite', hintText: 'dd/mm/aaaa', filled: true, fillColor: Color(0xFF0D0D0D), suffixIcon: Icon(Icons.calendar_today)), style: const TextStyle(color: Colors.white)))),
              const SizedBox(height: 12),
              const Text('Ícono', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: List.generate(_icons.length, (i) {
                final selected = i == _selectedIcon;
                return ChoiceChip(
                  label: Column(mainAxisSize: MainAxisSize.min, children: [Icon(_icons[i], color: selected ? Colors.black : Colors.white), const SizedBox(height: 4), Text(_iconLabels[i], style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12))]),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedIcon = i),
                  selectedColor: const Color(0xFFF7D35C),
                  backgroundColor: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              })),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))), const SizedBox(width: 8), ElevatedButton(onPressed: _create, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7D35C), foregroundColor: Colors.black), child: const Text('Crear Meta'))]),
            ],
          ),
        ),
      ),
    );
  }
}
