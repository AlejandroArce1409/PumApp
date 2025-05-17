// lib/recursos_screen.dart
// Programación Móvil - "PumApp"
// Alejandro Arce
// Brenda Bravo
// Páginas de interes para el alumno segmentadas por categorias y filtros

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelo simple de recurso
class Recurso {
  final String title;
  final String description;
  final String url;
  final String category;
  Recurso({
    required this.title,
    required this.description,
    required this.url,
    required this.category,
  });
}

class RecursosScreen extends StatefulWidget {
  const RecursosScreen({Key? key}) : super(key: key);
  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  final List<Recurso> _allResources = [
    Recurso(
      title: 'Manuales de acceso (Ciencias)',
      description:
      'Herramientas interactivas para comprender el uso de plataformas.',
      url: 'https://sites.google.com/ciencias.unam.mx/educacion-en-linea/guías-y-manuales',
      category: 'Web',
    ),
    Recurso(
      title: 'Guía para la Elaboración de Tesis (UNAM - Posgrado)',
      description:
      'Documento con lineamientos y consejos para escribir una tesis de posgrado.',
      url: 'https://tesiunam.dgb.unam.mx',
      category: 'PDF',
    ),
    Recurso(
      title: 'Podcast de Divulgación Científica de la UNAM (Ejemplo)',
      description:
      'Grabaciones de audio sobre temas científicos de interés general.',
      url: 'https://radiopodcast.unam.mx/podcast',
      category: 'Audio',
    ),
    Recurso(
      title: 'Recursos para el Aprendizaje de Matemáticas en Línea',
      description: 'Plataformas y herramientas interactivas para practicar matemáticas.',
      url: 'https://www.fi.unam.mx/calculoI',
      category: 'Matemáticas',
    ),
    Recurso(
      title: 'Galería de Arte Digital de la UNAM (Ejemplo)',
      description: 'Exhibición virtual de obras artísticas producidas por la UNAM.',
      url: 'https://muac.unam.mx/espacios',
      category: 'Arte',
    ),
    Recurso(
      title: 'Tutorial de Python para Principiantes',
      description: 'Curso introductorio a la programación en Python.',
      url: 'https://aprendepython.unam.mx',
      category: 'Programación',
    ),
    Recurso(
      title: 'Historia de México en Línea',
      description: 'Clases y recursos multimedia sobre la historia nacional.',
      url: 'https://historia.unam.mx',
      category: 'Historia',
    ),
    Recurso(
      title: 'Química Orgánica: Apuntes y Ejercicios',
      description: 'Ejercicios resueltos de química orgánica.',
      url: 'https://quimica.unam.mx/org',
      category: 'Química',
    ),
    Recurso(
      title: 'Laboratorio Virtual de Física',
      description: 'Simulaciones y prácticas de física moderna.',
      url: 'https://fisicavirtual.unam.mx',
      category: 'Física',
    ),
    Recurso(
      title: 'Introducción a la Estadística',
      description: 'Videos y tutoriales sobre estadística descriptiva.',
      url: 'https://estadistica.unam.mx/intro',
      category: 'Estadística',
    ),
    Recurso(
      title: 'Inglés Interactivo UNAM',
      description: 'Lecciones y ejercicios de inglés en línea.',
      url: 'https://idiomas.unam.mx/ingles',
      category: 'Idiomas',
    ),
    Recurso(
      title: 'Taller de Redacción Académica',
      description: 'Consejos para mejorar tus escritos universitarios.',
      url: 'https://redaccion.unam.mx',
      category: 'Generales',
    ),
    Recurso(
      title: 'Repositorio de Tesis UNAM',
      description: 'Descarga de tesis de licenciatura y posgrado.',
      url: 'https://tesiunam.dgb.unam.mx/repositorio',
      category: 'Tesis',
    ),
    Recurso(
      title: 'Bases de Datos con MySQL',
      description: 'Curso básico de bases de datos relacionales.',
      url: 'https://bd.unam.mx/mysql',
      category: 'Informática',
    ),
    Recurso(
      title: 'Psicología para Estudiantes',
      description: 'Conceptos introductorios en psicología educativa.',
      url: 'https://psicounam.mx/base',
      category: 'Humanidades',
    ),
    Recurso(
      title: 'Técnicas de Estudio Efectivo',
      description: 'Métodos y estrategias para aprender mejor.',
      url: 'https://estudios.unam.mx/tecnicas',
      category: 'Generales',
    ),
    Recurso(
      title: 'Seminarios de Investigación',
      description: 'Grabaciones de seminarios impartidos por profesores UNAM.',
      url: 'https://seminarios.unam.mx',
      category: 'Audio',
    ),
    Recurso(
      title: 'Bolsa de Trabajo UNAM',
      description: 'Oportunidades de prácticas profesionales y empleos.',
      url: 'https://bolsatrabajo.unam.mx',
      category: 'Generales',
    ),
  ];

  String _filterText = '';
  String _selectedCategory = 'Todos';

  // Mantenemos un mapa de categorías a Color, asignados en orden único:
  late final Map<String, Color> _categoryColors;

  @override
  void initState() {
    super.initState();
    _initCategoryColors();
  }

  void _initCategoryColors() {
    final palette = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.amber.shade400,
      Colors.indigo.shade400,
      Colors.brown.shade400,
      Colors.pink.shade400,
      Colors.cyan.shade400,
      Colors.lime.shade400,
      Colors.deepOrange.shade400,
      Colors.deepPurple.shade400,
    ];
    final cats = {
      'Todos',
      ..._allResources.map((r) => r.category)
    }.toList();
    _categoryColors = {
      for (var i = 0; i < cats.length; i++)
        cats[i]: palette[i % palette.length]
    };
  }

  @override
  Widget build(BuildContext context) {
    // Aplico filtro de texto y categoría
    final filtered = _allResources.where((r) {
      final matchCat = (_selectedCategory == 'Todos' || r.category == _selectedCategory);
      final matchText = r.title.toLowerCase().contains(_filterText) ||
          r.description.toLowerCase().contains(_filterText);
      return matchCat && matchText;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A243C),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCA242),
        title: const Text('Recursos', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              // Barra de búsqueda
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar recursos...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _filterText = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              // Lista de chips de categorías
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', ..._categoryColors.keys.where((c) => c!='Todos')].map((cat) {
                    final color = _categoryColors[cat]!;
                    final selected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(color: Colors.white)),
                        selected: selected,
                        selectedColor: color,
                        backgroundColor: color.withOpacity(0.3),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final r = filtered[i];
          final color = _categoryColors[r.category]!;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: color.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 6,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(r.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(r.description, style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                onPressed: () async {
                  final uri = Uri.parse(r.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abrir el enlace')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
