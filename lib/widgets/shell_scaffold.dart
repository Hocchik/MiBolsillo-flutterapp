import 'package:flutter/material.dart';
import 'top_header.dart';

class ShellScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  const ShellScaffold({Key? key, required this.body, this.currentIndex = 0}) : super(key: key);

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        // Add should push to allow returning
        Navigator.pushNamed(context, '/add');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/coach');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/goals');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/statistics');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (i) => _onNavTap(context, i),
          backgroundColor: const Color(0xFF0E0E0E),
          selectedItemColor: const Color(0xFF9AEF5E),
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Agregar'),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Coach'),
            BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Análisis'),
          ],
        ),
      ),
    );
  }
}
