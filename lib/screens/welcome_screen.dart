import 'package:flutter/material.dart';
import '../widgets/gradient_button.dart';

class DarkFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DarkFeatureCard({Key? key, required this.icon, required this.title, required this.subtitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Color(0xFFBFF17A)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0B0B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)]),
                ),
                child: Center(child: Icon(Icons.auto_awesome, color: Colors.black, size: 40)),
              ),
              SizedBox(height: 12),
              Text('TuBolsillo', style: TextStyle(color: Color(0xFFBFF17A), fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Tu coach financiero personal', style: TextStyle(color: Colors.white54)),
              SizedBox(height: 24),

              // Cards estilo oscuro
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    DarkFeatureCard(icon: Icons.insights, title: 'Coach IA personalizado', subtitle: 'Consejos inteligentes para tus finanzas'),
                    DarkFeatureCard(icon: Icons.shield, title: 'Datos seguros', subtitle: 'Tu información protegida en la nube'),
                    DarkFeatureCard(icon: Icons.sync, title: 'Sincronización automática', subtitle: 'Accede desde cualquier dispositivo'),
                  ],
                ),
              ),

              SizedBox(height: 22),
              // Botón principal ancho con gradiente
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Crear mi cuenta gratis',
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Botón secundario bordeado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text('Ya tengo cuenta', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),

              SizedBox(height: 18),
              Divider(color: Colors.white24, indent: 48, endIndent: 48),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  // Acción para probar sin cuenta (ir al dashboard como invitado)
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: Icon(Icons.smartphone, color: Colors.white70),
                label: Text('Probar sin cuenta', style: TextStyle(color: Colors.white70)),
              ),

              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Al continuar, aceptas nuestros términos de servicio y política de privacidad', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}