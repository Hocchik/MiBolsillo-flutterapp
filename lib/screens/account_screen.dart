import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _username;
  String? _email;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService();
    final name = await auth.getUsername();
    final s = await auth.isSynced();
    setState(() {
      _username = name ?? 'Usuario';
      _email = name != null ? '$name@gmail.com' : null;
      _synced = s;
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
  }

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)), child: child);

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mi Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(radius: 28, backgroundColor: const Color(0xFF9AEF5E), child: const Icon(Icons.person, color: Colors.black)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_username ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(_email ?? '', style: const TextStyle(color: Colors.white70))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2E7D32)), child: const Text('Cuenta Premium', style: TextStyle(color: Colors.white, fontSize: 12))),
              ])
            ])),

            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estado de Sincronización', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(_synced ? Icons.cloud_done : Icons.cloud_off, color: _synced ? Colors.greenAccent : Colors.white54), const SizedBox(width: 8), Text(_synced ? 'Conectado y sincronizado' : 'No sincronizado', style: const TextStyle(color: Colors.white))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: _synced ? Colors.green[900] : Colors.white12, borderRadius: BorderRadius.circular(12)), child: Text(_synced ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white70)))
              ]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0F2E12), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Respaldo automático activo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Tus datos se sincronizan automáticamente en la nube cada vez que realizas cambios.', style: TextStyle(color: Colors.white70))])))]),
            ])),

            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestión de Datos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Exportar mis datos'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white)),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload), label: const Text('Importar datos'), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: const Text('Nota: Puedes exportar tus datos en cualquier momento como respaldo adicional.', style: TextStyle(color: Colors.white70)))
            ])),

            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Configuración', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.person, color: Colors.white70), title: const Text('Editar perfil', style: TextStyle(color: Colors.white)), onTap: () {}),
              ListTile(leading: const Icon(Icons.lock, color: Colors.white70), title: const Text('Privacidad y seguridad', style: TextStyle(color: Colors.white)), onTap: () {}),
            ])),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.exit_to_app, color: Colors.redAccent), label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent))),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
