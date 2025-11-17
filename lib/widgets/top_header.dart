import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TopHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  const TopHeader({super.key, this.title});

  @override
  State<TopHeader> createState() => _TopHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _TopHeaderState extends State<TopHeader> {
  String? _username;
  bool _synced = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService();
    final logged = await auth.isLoggedIn();
    if (!mounted) return;
    if (!logged) {
      setState(() {
        _username = null;
        _synced = false;
      });
      return;
    }
    final name = await auth.getUsername();
    final s = await auth.isSynced();
    if (!mounted) return;
    setState(() {
      _username = name;
      _synced = s;
    });
  }



  void _onProfileTap() async {
    final logged = await AuthService().isLoggedIn();
    if (!mounted) return;
    if (logged) {
      Navigator.pushReplacementNamed(context, '/account');
      return;
    }

    if (_dialogOpen) return; // prevent duplicates
    _dialogOpen = true;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Cuenta no disponible', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Debes iniciar sesión para acceder a tu cuenta', style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.pushNamed(ctx, '/login'); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AEF5E), foregroundColor: Colors.black), child: const Text('Iniciar Sesión'))
          ]),
        ),
      ),
    );

    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          // Left: logo
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFFF1C232)])),
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
            ),
          ]),

          const SizedBox(width: 10),

          // Middle: title and optional greeting (expandable)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('TuBolsillo', style: TextStyle(color: const Color(0xFFBFF17A), fontWeight: FontWeight.bold)),
                  if (_username != null) ...[
                    const SizedBox(width: 8),
                    Flexible(child: Text('¡Hola, ${_username!}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ]
                ]),
                if (widget.title != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(widget.title!, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
            ),
          ),

          // Right: sync status + icons (fixed size)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_username != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(children: [
                    Icon(_synced ? Icons.cloud_done : Icons.cloud_off, size: 16, color: _synced ? Colors.greenAccent : Colors.white24),
                    const SizedBox(width: 6),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(_synced ? 'Sincronizado' : 'No sincronizado', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              IconButton(onPressed: _onProfileTap, icon: const Icon(Icons.person, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
