import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    HapticFeedback.mediumImpact(); 
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Tasbih Digital",
          style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Jumlah Dzikir", style: TextStyle(fontSize: 20, color: Colors.tealAccent)),
            const SizedBox(height: 20),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFFFFD54F), width: 4),
                boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Center(
                child: Text('$_counter', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _incrementCounter,
              child: Container(
                width: 150, height: 150,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00897B)),
                child: const Icon(Icons.touch_app, size: 80, color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _resetCounter,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
