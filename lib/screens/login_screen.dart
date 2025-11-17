import 'package:flutter/material.dart';
import '../widgets/gradient_button.dart';
import '../services/app_config.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
  final api = AppConfig.apiInstance();
    try {
      final username = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final resp = await api.login(username, password);
      // Supongo que el backend devuelve { token: '...' }
      final token = resp['token'] as String?;
      if (token == null) throw Exception('Token no recibido');

      // Guardar token y estado de sesión
      final auth = AuthService();
      await auth.setAuthToken(token);
      await auth.setLoggedIn(true);
      await auth.setUsername(username.contains('@') ? username.split('@')[0] : username);
      await auth.setSynced(true);
    } catch (e) {
      // Mostrar error
      final err = e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $err')));
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = false);
    if (!mounted) return;
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
        title: Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
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
                  Center(child: Text('Bienvenido de vuelta', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  SizedBox(height: 6),
                  Center(child: Text('Ingresa a tu cuenta de TuBolsillo', style: TextStyle(color: Colors.white54))),
                  SizedBox(height: 18),

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

                  SizedBox(height: 18),
                  _loading ? Center(child: CircularProgressIndicator()) : GradientButton(text: 'Iniciar Sesión', onPressed: _submit, colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)]),

                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                    child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Colors.white70)),
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
