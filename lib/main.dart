import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Created on your machine by `flutterfire configure` (not in git).
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Students never see a login screen. Anonymous auth still gives each
  // device a uid, which the security rules use.
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const FixAmApp());
}

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
            'FixAm\nFirebase is connected.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
