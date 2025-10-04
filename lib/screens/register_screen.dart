import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Simular registro/llamada a backend
    await Future.delayed(Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Crear Cuenta', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 420),
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(color: Color(0xFF161616), borderRadius: BorderRadius.circular(14)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)])),
                      child: Icon(Icons.auto_awesome, color: Colors.black, size: 36),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('Únete a TuBolsillo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  SizedBox(height: 6),
                  Center(child: Text('Crea tu cuenta gratuita', style: TextStyle(color: Colors.white54))),
                  SizedBox(height: 18),

                  Text('Nombre completo', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Color(0xFF0E0E0E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.person, color: Colors.white24),
                    ),
                    validator: (v) => (v==null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                  ),
                  SizedBox(height: 12),

                  Text('Email', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'tu@email.com',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Color(0xFF0E0E0E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.email, color: Colors.white24),
                    ),
                    validator: (v) {
                      if (v==null || v.trim().isEmpty) return 'Ingresa tu email';
                      final emailReg = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                      if (!emailReg.hasMatch(v)) return 'Email inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 12),

                  Text('Contraseña', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Color(0xFF0E0E0E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.lock, color: Colors.white24),
                    ),
                    validator: (v) => (v==null || v.length < 6) ? 'Contraseña mínima 6 caracteres' : null,
                  ),

                  SizedBox(height: 14),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12), color: Color(0xFF0F2E12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Color(0xFF9AEF5E)), child: Text('GRATIS', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 8),
                            Expanded(child: Text('- Sincronización en todos tus dispositivos', style: TextStyle(color: Colors.white70))),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text('- Coach IA personalizado', style: TextStyle(color: Colors.white70)),
                        Text('- Respaldo seguro en la nube', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                  _loading ? Center(child: CircularProgressIndicator()) : GradientButton(text: 'Crear mi cuenta', onPressed: _submit, colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)]),

                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('¿Ya tienes cuenta? Inicia sesión aquí', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
