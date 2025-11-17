import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../utils/formatters.dart';
import '../services/repository.dart';

class Goal {
  String? clientId;
  String? serverId;
  String title;
  double target;
  double saved;
  DateTime? deadline;
  IconData icon;

  Goal({this.clientId, this.serverId, required this.title, required this.target, this.saved = 0, this.deadline, required this.icon});

  int get progressPercent {
    if (target <= 0) return 0;
    final pct = (saved / target * 100).clamp(0, 100);
    return pct.round();
  }

  factory Goal.fromMap(Map<String, dynamic> m) {
    return Goal(
      clientId: m['clientId'] as String?,
      serverId: m['serverId'] as String?,
      title: m['title'] as String? ?? 'Meta',
      target: (m['target_amount'] as num?)?.toDouble() ?? (m['target'] as num?)?.toDouble() ?? 0.0,
      saved: (m['saved_amount'] as num?)?.toDouble() ?? (m['saved'] as num?)?.toDouble() ?? 0.0,
      deadline: m['deadline'] == null ? null : DateTime.tryParse(m['deadline'] as String),
      icon: Icons.adjust,
    );
  }

  Map<String, dynamic> toRecord() {
    return {
      'clientId': clientId,
      'serverId': serverId,
      'title': title,
      'target_amount': target,
      'saved_amount': saved,
      'deadline': deadline?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'extra': null,
    };
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final rows = await Repository().getLocalGoals();
    final loaded = rows.map((r) => Goal.fromMap(r)).toList();
    if (mounted) {
      setState(() {
        _goals
          ..clear()
          ..addAll(loaded);
      });
    }
  }

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
      // Use repository to persist and get canonical record (clientId/serverId)
      final payload = {
        'title': newGoal.title,
        'target_amount': newGoal.target,
        'saved_amount': newGoal.saved,
        'deadline': newGoal.deadline?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'extra': null,
      };

      try {
        final resp = await Repository().createGoal(payload);
        // resp will be either server response or the local record
        final record = Map<String, dynamic>.from(resp);
        final g = Goal.fromMap(record);
        if (!mounted) return;
        setState(() => _goals.insert(0, g));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta creada')));
      } catch (e) {
        // Show user-friendly message for validation errors
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Error al crear la meta';
        if (!mounted) return;
        // fallback: show the local instance only if it doesn't violate limits
        setState(() => _goals.insert(0, newGoal));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
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
              CircleAvatar(backgroundColor: Colors.deepOrange.shade800.withAlpha((0.2 * 255).round()), child: Icon(g.icon, color: Colors.yellow[700])),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${fmtMoneyOrPlaceholder(g.saved)} / ${fmtMoneyOrPlaceholder(g.target)}', style: const TextStyle(color: Colors.white70)), Text(g.deadline == null ? '' : _deadlineLabel(g.deadline!), style: const TextStyle(color: Colors.yellow))]),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(onPressed: () => _onContribute(g), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.black), child: const Text('Aportar')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => _showDetails(g), style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Ver detalles')),
          ])
        ],
      ),
    );
  }

  Future<void> _onContribute(Goal g) async {
    final ctrl = TextEditingController();
    final res = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aportar a la meta'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Cantidad a aportar')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            final v = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
            Navigator.of(ctx).pop(v);
          }, child: const Text('Aportar')),
        ],
      ),
    );

    if (res == null || res <= 0) return;

    // Ensure the goal has an identifier in local DB. If both clientId and serverId are missing
    // persist the goal via Repository.createGoal to generate a clientId and enqueue sync.
    String? idToUse = g.clientId ?? g.serverId;
    if (idToUse == null) {
      final rec = await Repository().createGoal(g.toRecord());
      final created = Map<String, dynamic>.from(rec);
      final createdGoal = Goal.fromMap(created);
      // replace the UI instance with the canonical one
      if (!mounted) return;
      setState(() {
        final idx = _goals.indexOf(g);
        if (idx >= 0) _goals[idx] = createdGoal;
      });
      idToUse = created['clientId'] as String? ?? created['serverId'] as String?;
      // update g reference to the updated goal for optimistic UI
      g = _goals.firstWhere((x) => x.clientId == idToUse || x.serverId == idToUse, orElse: () => g);
    }

    // optimistic update
    setState(() => g.saved += res);

    try {
      // repository will look up by clientId or serverId
      final resp = await Repository().contributeToGoal(idToUse!, res);
      final updated = Map<String, dynamic>.from(resp);
      final updatedGoal = Goal.fromMap(updated);
      if (!mounted) return;
      setState(() {
        final idx = _goals.indexWhere((x) => x.clientId == updatedGoal.clientId || x.serverId == updatedGoal.serverId);
        if (idx >= 0) _goals[idx] = updatedGoal;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aporte registrado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aporte guardado localmente (sincronización pendiente)')));
    }
  }

  Future<void> _showDetails(Goal g) async {
    // Fetch contributions for this goal
    final goalClientId = g.clientId;
    final contributions = <Map<String, dynamic>>[];
    double separatedForGoal = 0.0;
    if (goalClientId != null) {
      try {
        final rows = await Repository().getContributionsForGoal(goalClientId);
        contributions.addAll(rows);
        separatedForGoal = await Repository().getSeparatedForGoal(goalClientId);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(g.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            Text(fmtMoneyOrPlaceholder(g.saved), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Row(children: [Text('Separado: ', style: const TextStyle(color: Colors.white70)), Text(fmtMoneyOrPlaceholder(separatedForGoal), style: const TextStyle(color: Colors.white))]),
          const SizedBox(height: 8),
          Row(children: [Text('Objetivo: ', style: const TextStyle(color: Colors.white70)), Text(fmtMoneyOrPlaceholder(g.target), style: const TextStyle(color: Colors.white))]),
          const SizedBox(height: 6),
          if (g.deadline != null) Text('Fecha límite: ${g.deadline!.day}/${g.deadline!.month}/${g.deadline!.year}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          const Text('Historial de aportes', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (contributions.isEmpty)
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('No hay aportes todavía', style: TextStyle(color: Colors.white54))))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: contributions.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                itemBuilder: (ctx2, i) {
                  final r = contributions[i];
                  final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
                  String dateLabel = '';
                  try {
                    final d = DateTime.parse(r['createdAt'] as String);
                    dateLabel = '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                  } catch (_) {
                    dateLabel = r['createdAt']?.toString() ?? '';
                  }
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(fmtMoneyOrPlaceholder(amt), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(dateLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))), const SizedBox(width: 8), OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text('Eliminar meta'),
                  content: const Text('¿Seguro que desea eliminar la meta?'),
                  actions: [TextButton(onPressed: () => Navigator.of(confirmCtx).pop(false), child: const Text('Cancelar')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(confirmCtx).pop(true), child: const Text('Eliminar'))],
                ),
              );
              if (confirmed == true) {
                try {
                  final idToUse = g.clientId ?? g.serverId;
                  if (idToUse == null) throw Exception('Meta sin identificador');

                  // compute separated amount for this goal to show in confirmation/undo
                  double separatedForGoal = 0.0;
                  try {
                    if (g.clientId != null) {
                      separatedForGoal = await Repository().getSeparatedForGoal(g.clientId!);
                    } else if (g.serverId != null) {
                      // best-effort: try to find clientId by scanning local goals
                      final all = await Repository().getLocalGoals();
                      final found = all.firstWhere((x) => (x['serverId'] as String?) == g.serverId, orElse: () => {});
                      final fid = found['clientId'] as String?;
                      if (fid != null) separatedForGoal = await Repository().getSeparatedForGoal(fid);
                    }
                  } catch (_) {}

                  final delCtx = await Repository().deleteGoal(idToUse);
                  if (!mounted) return;
                  setState(() => _goals.removeWhere((x) => x.clientId == g.clientId || x.serverId == g.serverId));
                  Navigator.of(context).pop();

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(SnackBar(
                    content: Text('Meta eliminada — Separado eliminado: ${fmtMoneyOrPlaceholder(separatedForGoal)}'),
                    action: SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () async {
                        try {
                          await Repository().undoDeleteGoal(delCtx['goal'] as Map<String, dynamic>?, List<Map<String, dynamic>>.from(delCtx['contributions'] ?? []), List<String>.from(delCtx['queuedClientIds'] ?? []));
                          if (!mounted) return;
                          // restore to UI
                          final restored = delCtx['goal'] as Map<String, dynamic>?;
                          if (restored != null) {
                            setState(() {
                              _goals.insert(0, Goal.fromMap(restored));
                            });
                          }
                          messenger.showSnackBar(const SnackBar(content: Text('Meta restaurada')));
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('No se pudo restaurar: ${e.toString()}')));
                        }
                      },
                    ),
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.toString()}')));
                }
              }
            },
            child: const Text('Eliminar'),
          )]),
        ]),
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

            if (_goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('No tienes metas todavía', style: TextStyle(color: Colors.white54))),
                ),
              )
            else
              ..._goals.map(_goalCard),

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
