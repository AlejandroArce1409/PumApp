// lib/comunidad_screen.dart

/*
  Proyecto: Programación Móvil – PumApp
  Alejandro Arce
  Brenda Bravo

  Pantalla "Comunidad":
  Muestra enlaces de interés institucional de forma clara y profesional.
  Cada tarjeta abre el link correspondiente en el navegador externo.
*/

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({Key? key}) : super(key: key);

  // Definimos una lista constante de enlaces con título, subtítulo, URL e ícono.
  static const List<_Enlace> _enlaces = [
    _Enlace(
      title: 'SIAE UNAM',
      subtitle: 'Sistema Integral de Administración Escolar',
      url: 'https://www.dgae-siae.unam.mx/',
      icon: Icons.school,
    ),
    _Enlace(
      title: 'Integra UNAM',
      subtitle: 'Gestión académica y trámites',
      url: 'https://www.integra.unam.mx/',
      icon: Icons.account_tree,
    ),
    _Enlace(
      title: 'Correo Institucional',
      subtitle: 'Acceso a tu correo @unam.mx',
      url: 'https://correo.unam.mx',
      icon: Icons.email,
    ),
    _Enlace(
      title: 'Biblioteca UNAM',
      subtitle: 'Recursos y catálogos en línea',
      url: 'https://bidi.unam.mx/',
      icon: Icons.local_library,
    ),
    _Enlace(
      title: 'DGENP',
      subtitle: 'Dirección General de Educación Media Superior',
      url: 'http://enp.unam.mx/',
      icon: Icons.public,
    ),
    _Enlace(
      title: 'Trámites y Servicios',
      subtitle: 'Portal Único de Trámites UNAM',
      url: 'https://www.dgae.unam.mx/',
      icon: Icons.build,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A243C), // Color de fondo institucional
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCA242),
        title: const Text(
          'Comunidad',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        itemCount: _enlaces.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final e = _enlaces[i];
          return Card(
            color: const Color(0xFF1E3A56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFCCA242),
                child: Icon(e.icon, color: Colors.black),
              ),
              title: Text(
                e.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                e.subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.white54),
              onTap: () async {
                final uri = Uri.parse(e.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el enlace')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// Clase auxiliar para definir cada enlace de la comunidad
class _Enlace {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;

  const _Enlace({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}
