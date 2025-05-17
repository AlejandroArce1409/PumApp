// lib/profile_screen.dart

// Programación Móvil - "PumApp"
// Alejandro Arce
// Brenda Bravo
//Pantalla de perfil donde el usuario puede editar sus datos,
// elegir foto de perfil, ver y eliminar sus materias (cargadas desde el simulador).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

/// Modelo de clase periódica que coincide con el de calendar_screen.dart
class ClassEvent {
  String subject;
  List<int> daysOfWeek;
  TimeOfDay start, end;
  MaterialColor color;

  ClassEvent({
    required this.subject,
    required this.daysOfWeek,
    required this.start,
    required this.end,
    required this.color,
  });

  /// Convierte a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
    'subject': subject,
    'daysOfWeek': daysOfWeek,
    'startHour': start.hour,
    'startMinute': start.minute,
    'endHour': end.hour,
    'endMinute': end.minute,
    'color': color.value,
  };

  /// Reconstruye el objeto desde JSON
  static ClassEvent fromJson(Map<String, dynamic> j) {
    final storedColor = j['color'] as int;
    final found = Colors.primaries.firstWhere(
          (c) => c.value == storedColor,
      orElse: () => Colors.blue,
    );
    return ClassEvent(
      subject: j['subject'],
      daysOfWeek: List<int>.from(j['daysOfWeek']),
      start: TimeOfDay(hour: j['startHour'], minute: j['startMinute']),
      end: TimeOfDay(hour: j['endHour'], minute: j['endMinute']),
      color: found,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controladores para nombre y matrícula
  final _nameCtrl    = TextEditingController();
  final _accountCtrl = TextEditingController();

  // Estado del plantel seleccionado y la foto de perfil
  String _plantel    = 'Añadir escuela';
  File? _profileImage;

  // Lista de planteles para el dropdown
  final List<String> _planteles = [
    // ... listado de preparatorias, CCH, FES, C.U.
    'Prepa No. 1 Gabino Barreda',
    'Prepa No. 2 Erasmo Castellanos Quinto',
    // (resto de planteles)
    'Ciudad Universitaria (C.U.)'
  ];

  // Materias cargadas desde SharedPreferences
  List<ClassEvent> _materias = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();   // Carga datos de perfil
    _loadMaterias();  // Carga materias del horario
  }

  /// Carga nombre, cuenta, plantel y foto del usuario de SharedPreferences
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text    = prefs.getString('name') ?? '';
    _accountCtrl.text = prefs.getString('account') ?? '';
    _plantel          = prefs.getString('plantel') ?? _planteles.first;
    final imgPath     = prefs.getString('profile_image');
    if (imgPath != null && File(imgPath).existsSync()) {
      setState(() => _profileImage = File(imgPath));
    }
  }

  /// Carga las materias guardadas en SharedPreferences
  Future<void> _loadMaterias() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pumapp_classes') ?? [];
    _materias = list
        .map((s) => ClassEvent.fromJson(json.decode(s)))
        .toList();
    setState(() {});
  }

  /// Permite al usuario escoger una imagen de la galería y guardarla localmente
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir  = await getApplicationDocumentsDirectory();
    final name = path.basename(picked.path);
    final img  = File('${dir.path}/$name');
    await File(picked.path).copy(img.path);

    setState(() => _profileImage = img);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', img.path);
  }

  /// Guarda los datos de nombre, cuenta y plantel en SharedPreferences
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name',    _nameCtrl.text.trim());
    await prefs.setString('account', _accountCtrl.text.trim());
    await prefs.setString('plantel', _plantel);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil guardado')),
    );
  }

  /// Cierra la sesión de Firebase y regresa al login
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// Elimina una materia tras pedir confirmación al usuario
  void _removeMateria(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar "${_materias[index].subject}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      _materias.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'pumapp_classes',
        _materias.map((c) => json.encode(c.toJson())).toList(),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A243C),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCA242),
        title: const Text('PumApp – Perfil', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Zona de foto de perfil (tap para elegir imagen)
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 48, color: Colors.white70)
                    : null,
              ),
            ),

            const SizedBox(height: 12),
            // Campo de texto para nombre
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 12),
            // Campo de texto para matrícula/cuenta
            TextField(
              controller: _accountCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'No de Cuenta',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 12),
            // Selector de plantel/facultad
            DropdownButtonFormField<String>(
              value: _plantel,
              decoration: InputDecoration(
                labelText: 'Plantel / Facultad',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _planteles.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p, style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (v) => setState(() => _plantel = v!),
              dropdownColor: const Color(0xFF0A243C),
            ),

            const SizedBox(height: 20),
            // Botones de guardar perfil y cerrar sesión
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCCA242),
                    foregroundColor: Colors.black,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            // Sección de "Mis materias" con grid y eliminación por long-press
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Mis materias',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _materias.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 140,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (ctx, i) {
                final m = _materias[i];
                return GestureDetector(
                  onLongPress: () => _removeMateria(i), // Para eliminar la materia
                  child: Container(
                    decoration: BoxDecoration(
                      color: m.color.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.subject,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black)),
                        const SizedBox(height: 4),
                        Text(
                          'Días: ${m.daysOfWeek.map((d) => ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'][d-1]).join(', ')}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        Text(
                          'Hora: ${m.start.format(context)}–${m.end.format(context)}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
