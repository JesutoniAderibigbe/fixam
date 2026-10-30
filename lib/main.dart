import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Created on your machine by `flutterfire configure` (not in git).
import 'data/firestore_ticket_repository.dart';
import 'firebase_options.dart';
import 'ui/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Guardrail: only your genuine app can call Gemini through Firebase.
  // In debug, copy the debug token from the logs into the Firebase console.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );

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
      home: ChatScreen(repo: FirestoreTicketRepository()),
    );
  }
}
