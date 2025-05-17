// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'home.dart';
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InicializadorApp());
}

class InicializadorApp extends StatelessWidget {
  const InicializadorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PumApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A243C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCCA242),
          primary: const Color(0xFFCCA242),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<FirebaseApp>(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          // 1. Mientras se inicializa, mostramos Splash
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          // 2. Si hay error, lo avisamos
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Text(
                  'Error al inicializar Firebase:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // 3. Si inicializó bien, vemos si hay usuario
          final user = FirebaseAuth.instance.currentUser;
          return user != null ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Por si quieres esperar un mínimo de tiempo:
    Timer(const Duration(seconds: 3), () {
      // Una vez pase el timer, reconstruye para que el FutureBuilder avance
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A243C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pumapp_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            const Text(
              'PumApp',
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFFCCA242),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu vida académica, organizada 🐾',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFFCCA242),
            ),
          ],
        ),
      ),
    );
  }
}
