import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // quita la franja de debug
      title: 'Mi primera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();
  int _numeroSecreto = 0;
  String _mensaje = "Adivina un número del 1 al 10";

  @override
  void initState() {
    super.initState();
    _numeroSecreto = _random.nextInt(10) + 1;
  }

  void _verificarNumero() {
    final int? valor = int.tryParse(_controller.text);
    if (valor == null) {
      setState(() {
        _mensaje = "Por favor ingresa un número válido 😅";
      });
      return;
    }

    if (valor == _numeroSecreto) {
      setState(() {
        _mensaje = "🎉 ¡Correcto! El número era $_numeroSecreto";
        _numeroSecreto = _random.nextInt(10) + 1; // reinicia el juego
      });
    } else if (valor < _numeroSecreto) {
      setState(() {
        _mensaje = "🔼 Intenta con un número más grande";
      });
    } else {
      setState(() {
        _mensaje = "🔽 Intenta con un número más pequeño";
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hola Mundo en Flutter 🚀"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Escribe un número",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verificarNumero,
              child: const Text("Probar suerte 🎲"),
            ),
          ],
        ),
      ),
    );
  }
}
