import 'package:flutter/material.dart';
import '../services/repository.dart';
import '../services/currency_service.dart';

enum TxType { income, expense }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _step = 0;
  bool _saving = false;
  TxType? _type;
  final TextEditingController _amountCtrl = TextEditingController(text: '0');
  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];
  String? _selectedCategory;
  final List<String> _incomeCategories = ['Salario', 'Freelance', 'Inversiones', 'Regalo', 'Otros'];
  final List<String> _expenseCategories = ['Comida', 'Transporte', 'Servicios', 'Entretenimiento', 'Salud', 'Otros'];
  List<String> get _categories => _type == TxType.expense ? _expenseCategories : _incomeCategories;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _type == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selecciona tipo de transacción')));
      return;
    }
    if (_step == 1) {
      final value = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingresa un monto válido')));
        return;
      }
    }
    setState(() {
      if (_step < 2) _step++;
    });
  }

  void _back() {
    setState(() {
      if (_step > 0) _step--;
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _save() {
    if (_saving) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    // Parse the entered amount in the currently selected currency and convert
    // it to the app base currency (USD) for storage.
    final parsed = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final amount = CurrencyService().convertToBase(parsed);
    final tx = {
      'type': _type == TxType.income ? 'income' : 'expense',
      'amount': amount,
      'category': _selectedCategory,
      'note': _noteCtrl.text.trim(),
      'date': DateTime.now().toIso8601String(),
    };

    // Use Repository to persist locally and attempt immediate sync.
    _sendToServerOrReturnLocal(tx);
  }

  Future<void> _sendToServerOrReturnLocal(Map<String, dynamic> tx) async {
    // Ensure timestamps are present; Repository will generate clientId
    tx['createdAt'] = tx['date'] ?? DateTime.now().toIso8601String();
    tx['updatedAt'] = DateTime.now().toIso8601String();
    if (!mounted) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    // show a saving snackbar while the operation runs; we'll auto-hide/redirect after a timeout
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Row(children: const [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Guardando...')]),
    ));

    // fallback: if still saving after timeout, hide snackbar and navigate back with local tx
    Future.delayed(const Duration(seconds: 6)).then((_) {
      if (_saving && mounted) {
        try {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(const SnackBar(content: Text('Guardado localmente (sincronización pendiente)')));
          if (mounted) Navigator.pop(context, tx);
        } catch (_) {}
      }
    });

    try {
      final resp = await Repository().createTransaction(tx);
      // always hide the 'Guardando...' snackbar even if widget unmounted
      messenger.hideCurrentSnackBar();
      if (resp['serverId'] != null) {
        if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Transacción sincronizada')));
      } else {
        if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Transacción guardada localmente')));
      }
      // small delay so user sees the success message, then return
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, resp);
    } catch (_) {
      // ensure snackbar is hidden even on error
      messenger.hideCurrentSnackBar();
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Error al guardar la transacción')));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, tx);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i <= _step;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? Color(0xFF9AEF5E) : Colors.grey[800],
            shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.transparent : Colors.white24),
          ),
          child: Center(child: Text('${i + 1}', style: TextStyle(color: active ? Colors.black : Colors.white70))),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Agregar', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                _buildStepIndicator(),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
                  child: _step == 0 ? _buildStepType() : (_step == 1 ? _buildStepAmount() : _buildStepCategory()),
                ),

                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: _cancel, child: Text('Cancelar', style: TextStyle(color: Colors.white70))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepType() {
    return Column(
      children: [
        Text('¿Qué tipo de transacción es?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        GestureDetector(
              onTap: () => setState(() {
                _type = TxType.income;
                _selectedCategory = null;
              }),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _type == TxType.income ? Colors.green[700] : Color(0xFF121212),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _type == TxType.income ? Colors.green[600]! : Colors.white24),
            ),
            child: Row(children: [
              CircleAvatar(backgroundColor: _type == TxType.income ? Colors.green : Colors.white10, child: Icon(Icons.arrow_upward, color: Colors.white)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ingreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Dinero que recibes', style: TextStyle(color: Colors.white70))])),
            ]),
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() {
            _type = TxType.expense;
            _selectedCategory = null;
          }),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _type == TxType.expense ? Colors.red[700] : Color(0xFF121212),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _type == TxType.expense ? Colors.red[600]! : Colors.white24),
            ),
            child: Row(children: [
              CircleAvatar(backgroundColor: _type == TxType.expense ? Colors.red : Colors.white10, child: Icon(Icons.arrow_downward, color: Colors.white)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Dinero que gastas', style: TextStyle(color: Colors.white70))])),
            ]),
          ),
        ),
        SizedBox(height: 16),
        Row(children: [Expanded(child: OutlinedButton(onPressed: _cancel, child: Text('Cancelar', style: TextStyle(color: Colors.white)))), SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF9AEF5E), foregroundColor: Colors.black), child: Text('Continuar')))],),
      ],
    );
  }

  Widget _buildStepAmount() {
    final title = _type == TxType.expense ? '¿Cuánto gastaste?' : '¿Cuánto recibiste?';
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(CurrencyService().symbols[CurrencyService().selectedCurrency] ?? '\$', style: TextStyle(color: Colors.white, fontSize: 28)),
            SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Text('Cantidades rápidas', style: TextStyle(color: Colors.white70))),
        SizedBox(height: 8),
        Wrap(spacing: 8, children: _quickAmounts.map((v) {
          final sym = CurrencyService().symbols[CurrencyService().selectedCurrency] ?? '\$';
          return OutlinedButton(
            onPressed: () => setState(() => _amountCtrl.text = v.toString()),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24), backgroundColor: Color(0xFF121212)),
            child: Text('$sym$v'),
          );
        }).toList()),
        SizedBox(height: 16),
            Row(children: [Expanded(child: OutlinedButton(onPressed: _back, child: Text('Atrás', style: TextStyle(color: Colors.white)))), SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _saving ? null : _next, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF9AEF5E), foregroundColor: Colors.black), child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Continuar')))],),
      ],
    );
  }

  Widget _buildStepCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Elige una categoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) {
          final selected = _selectedCategory == c;
          return ChoiceChip(
            label: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(c, style: TextStyle(color: selected ? Colors.black : Colors.white))),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = c),
            selectedColor: Color(0xFF9AEF5E),
            backgroundColor: Color(0xFF121212),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        }).toList()),
        SizedBox(height: 12),
        Text('Descripción (opcional)', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 8),
        TextField(controller: _noteCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Agrega una nota...', hintStyle: TextStyle(color: Colors.white24), filled: true, fillColor: Color(0xFF0E0E0E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        SizedBox(height: 16),
        Row(children: [Expanded(child: OutlinedButton(onPressed: _back, child: Text('Atrás', style: TextStyle(color: Colors.white)))), SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _saving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF9AEF5E), foregroundColor: Colors.black), child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Guardar')))],),
      ],
    );
  }
}
