import 'package:flutter/material.dart';

void main() => runApp(const FixAmApp());

class FixAmApp extends StatelessWidget {
  const FixAmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixAm',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4285F4)),
      home: const Scaffold(
        body: Center(
          child: Text(
            'FixAm\nYour agent builds the rest.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
