// lib/login_screen.dart

/*
  Proyecto: Programación Móvil – PumApp
  Brenda Bravo
  Alejandro Arce

  Este widget permite al usuario iniciar sesión con correo institucional
  (@aragon.unam.mx o @comunidad.unam.mx). Si no tiene cuenta, puede
  navegar a la pantalla de registro. Cada función está documentada
  para explicar su propósito y flujo.
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado para mostrar indicador de carga y mensajes de error
  bool _isLoading = false;
  String? _errorMessage;

  // Dominios permitidos para correo UNAM
  final allowedDomains = ["@aragon.unam.mx", "@comunidad.unam.mx"];

  /// Verifica que el correo termine en uno de los dominios permitidos.
  bool _isValidEmail(String email) {
    return allowedDomains.any((domain) => email.endsWith(domain));
  }

  /// Lógica de inicio de sesión:
  /// 1) Valida formato de correo.
  /// 2) Muestra indicador de carga.
  /// 3) Intenta iniciar sesión con Firebase Auth.
  /// 4) En caso de éxito, navega a HomeScreen.
  /// 5) En caso de error, muestra mensaje descriptivo.
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validación de dominio institucional
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = "Usa tu correo institucional UNAM");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Intento de autenticación
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Navegar a pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Captura y muestra mensaje de error de Firebase
      setState(() => _errorMessage = e.message);
    } finally {
      // Ocultar indicador de carga
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A243C),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono inicial de la app
                const Icon(Icons.school, size: 80, color: Color(0xFFCCA242)),
                const SizedBox(height: 16),

                // Título de bienvenida
                const Text(
                  'Bienvenido a PumApp',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFFCCA242),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Campo de correo
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Correo UNAM",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCCA242)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCCA242)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de inicio de sesión o indicador de carga
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFFCCA242))
                else
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCCA242),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text("Iniciar sesión"),
                  ),
                const SizedBox(height: 16),

                // Navegar a registro
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "¿No tienes cuenta? Crear una",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

                // Mostrar mensaje de error si existe
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
