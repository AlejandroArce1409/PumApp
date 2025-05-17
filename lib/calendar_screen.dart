// lib/calendar_screen.dart

/*
  Proyecto: Programación Móvil – PumApp
 Alejandro Arce
 Brenda Bravo
  Este archivo contiene la pantalla de Calendario y Horario de clases,
  con dos pestañas:
  1) Calendario mensual que muestra recordatorios puntuales.
  2) Horario semanal con materias periódicas y recordatorios asociados.

  - Se utilizan modelos Reminder y ClassEvent para serializar datos.
  - SharedPreferences guarda y recupera eventos locales.
  - Flutter Local Notifications programa avisos según antelación seleccionada.
  - TableCalendar muestra la vista mensual con marcadores de colores.
  - La vista semanal se construye con una tabla que permite múltiples materias en el mismo horario,
    selección de color profesional y eliminación por pulsación larga.
*/

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Modelo para recordatorios puntuales
class Reminder {
  final String title, category, difficulty, subject;
  final DateTime dateTime;

  Reminder({
    required this.title,
    required this.category,
    required this.difficulty,
    required this.subject,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'difficulty': difficulty,
    'subject': subject,
    'dateTime': dateTime.toIso8601String(),
  };

  static Reminder fromJson(Map<String, dynamic> j) => Reminder(
    title: j['title'],
    category: j['category'],
    difficulty: j['difficulty'],
    subject: j['subject'],
    dateTime: DateTime.parse(j['dateTime']),
  );
}

/// Modelo para clases periódicas
class ClassEvent {
  String subject;
  String? professor;
  String? room;
  List<int> daysOfWeek;
  TimeOfDay start, end;
  MaterialColor color;

  ClassEvent({
    required this.subject,
    this.professor,
    this.room,
    required this.daysOfWeek,
    required this.start,
    required this.end,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'professor': professor,
    'room': room,
    'daysOfWeek': daysOfWeek,
    'startHour': start.hour,
    'startMinute': start.minute,
    'endHour': end.hour,
    'endMinute': end.minute,
    'color': color.value,
  };

  static ClassEvent fromJson(Map<String, dynamic> j) {
    final storedColor = j['color'] as int;
    final found = Colors.primaries.firstWhere(
          (c) => c.value == storedColor,
      orElse: () => Colors.blue,
    );
    return ClassEvent(
      subject: j['subject'],
      professor: j['professor'] as String?,
      room: j['room'] as String?,
      daysOfWeek: List<int>.from(j['daysOfWeek']),
      start: TimeOfDay(hour: j['startHour'], minute: j['startMinute']),
      end: TimeOfDay(hour: j['endHour'], minute: j['endMinute']),
      color: found,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late FlutterLocalNotificationsPlugin _notifications;

  List<Reminder> _reminders = [];
  List<ClassEvent> _classes = [];
  static const _weekdayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _loadAll();
    _selectedDay = _focusedDay;
  }

  void _initNotifications() {
    _notifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    _notifications.initialize(const InitializationSettings(
      android: androidInit,
    ));
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    _reminders = (prefs.getStringList('pumapp_reminders') ?? [])
        .map((s) => Reminder.fromJson(json.decode(s)))
        .toList();
    _classes = (prefs.getStringList('pumapp_classes') ?? [])
        .map((s) => ClassEvent.fromJson(json.decode(s)))
        .toList();
    setState(() {});
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pumapp_reminders',
      _reminders.map((r) => json.encode(r.toJson())).toList(),
    );
  }

  Future<void> _saveClasses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pumapp_classes',
      _classes.map((c) => json.encode(c.toJson())).toList(),
    );
  }

  Future<void> _scheduleNotification(Reminder r) async {
    final dt = tz.TZDateTime.from(r.dateTime, tz.local);
    const det = AndroidNotificationDetails(
      'chan1',
      'Recordatorios',
      channelDescription: 'Tus recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notifications.zonedSchedule(
      dt.hashCode,
      r.title,
      '${r.subject} · ${r.category}',
      dt,
      NotificationDetails(android: det),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  void _onAddPressed() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.notification_add),
            title: const Text('Nuevo recordatorio'),
            onTap: () {
              Navigator.pop(context);
              _showEntryDialog(isReminder: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Nueva materia'),
            onTap: () {
              Navigator.pop(context);
              _showEntryDialog(isReminder: false);
            },
          ),
        ]),
      ),
    );
  }

  void _showEntryDialog({
    required bool isReminder,
    Reminder? rem,
    ClassEvent? cls,
  }) {
    final titleCtrl = TextEditingController(text: rem?.title);
    final subjCtrl =
    TextEditingController(text: rem?.subject ?? cls?.subject);
    final profCtrl = TextEditingController(text: cls?.professor);
    final roomCtrl = TextEditingController(text: cls?.room);

    String cat = rem?.category ?? 'Tarea';
    String diff = rem?.difficulty ?? 'Media';
    DateTime date = rem?.dateTime ?? _selectedDay ?? DateTime.now();
    TimeOfDay time = rem != null
        ? TimeOfDay.fromDateTime(rem.dateTime)
        : const TimeOfDay(hour: 8, minute: 0);
    int remindDays = 1;

    final daysSel = cls?.daysOfWeek.toSet() ?? {date.weekday};
    TimeOfDay start = cls?.start ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = cls?.end ?? const TimeOfDay(hour: 10, minute: 0);
    MaterialColor col = cls?.color ??
        Colors.primaries[Random().nextInt(Colors.primaries.length)];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, sb) {
        return AlertDialog(
          title: Text(isReminder
              ? (rem == null ? 'Nuevo recordatorio' : 'Editar recordatorio')
              : (cls == null ? 'Nueva materia' : 'Editar materia')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReminder) ...[
                  // Campos para recordatorio
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: subjCtrl,
                    decoration: const InputDecoration(labelText: 'Materia'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: cat,
                    decoration:
                    const InputDecoration(labelText: 'Categoría'),
                    items: ['Tarea', 'Examen', 'Proyecto', 'Otro']
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => sb(() => cat = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: diff,
                    decoration:
                    const InputDecoration(labelText: 'Dificultad'),
                    items: ['Fácil', 'Media', 'Difícil']
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => sb(() => diff = v!),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                        'Fecha: ${date.day}/${date.month}/${date.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                          context: ctx2,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030));
                      if (d != null) sb(() => date = d);
                    },
                  ),
                  ListTile(
                    title: Text('Hora: ${time.format(ctx2)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final t =
                      await showTimePicker(context: ctx2, initialTime: time);
                      if (t != null) sb(() => time = t);
                    },
                  ),
                  DropdownButtonFormField<int>(
                    value: remindDays,
                    decoration:
                    const InputDecoration(labelText: 'Antelación (días)'),
                    items: [1, 2, 3, 5, 7]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text('$e días')))
                        .toList(),
                    onChanged: (v) => sb(() => remindDays = v!),
                  ),
                ] else ...[
                  // Campos para materia
                  TextField(
                    controller: subjCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Materia'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: profCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Profesor'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roomCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Salón'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final wd = i + 1;
                      return ChoiceChip(
                        label: Text(_weekdayNames[i]),
                        selected: daysSel.contains(wd),
                        onSelected: (sel) => sb(() =>
                        sel ? daysSel.add(wd) : daysSel.remove(wd)),
                      );
                    }),
                  ),
                  ListTile(
                    title: Text('Inicio: ${start.format(ctx2)}'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () async {
                      final t =
                      await showTimePicker(context: ctx2, initialTime: start);
                      if (t != null) sb(() => start = t);
                    },
                  ),
                  ListTile(
                    title: Text('Fin: ${end.format(ctx2)}'),
                    trailing: const Icon(Icons.stop),
                    onTap: () async {
                      final t =
                      await showTimePicker(context: ctx2, initialTime: end);
                      if (t != null) sb(() => end = t);
                    },
                  ),
                  ListTile(
                    title: const Text('Color'),
                    trailing: GestureDetector(
                      onTap: () => showDialog(
                        context: ctx2,
                        builder: (_) => AlertDialog(
                          title: const Text('Selector de color'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: col,
                              onColorChanged: (c) => sb(
                                      () => col = MaterialColor(c.value, {500: c})),
                              showLabel: false,
                              pickerAreaHeightPercent: 0.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx2),
                                child: const Text('Listo'))
                          ],
                        ),
                      ),
                      child: CircleAvatar(backgroundColor: col, radius: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (isReminder) {
                  final nr = Reminder(
                    title: titleCtrl.text,
                    category: cat,
                    difficulty: diff,
                    subject: subjCtrl.text,
                    dateTime: DateTime(date.year, date.month, date.day,
                        time.hour, time.minute),
                  );
                  if (rem != null) _reminders.remove(rem);
                  _reminders.add(nr);
                  _saveReminders();
                  _scheduleNotification(nr);
                } else {
                  final ce = ClassEvent(
                    subject: subjCtrl.text,
                    professor: profCtrl.text,
                    room: roomCtrl.text,
                    daysOfWeek: daysSel.toList(),
                    start: start,
                    end: end,
                    color: col,
                  );
                  if (cls != null) _classes.remove(cls);
                  _classes.add(ce);
                  _saveClasses();
                }
                setState(() {});
                Navigator.pop(ctx2);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteClass(ClassEvent ev) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar "${ev.subject}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              _classes.remove(ev);
              _saveClasses();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  /// Construye la vista mensual del calendario con marcadores
  Widget _buildMonthly() {
    return TableCalendar<Reminder>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      onDaySelected: (sel, foc) {
        setState(() {
          _selectedDay = sel;
          _focusedDay = foc;
        });
      },
      eventLoader: (d) => _reminders
          .where((r) =>
      r.dateTime.year == d.year &&
          r.dateTime.month == d.month &&
          r.dateTime.day == d.day)
          .toList(),
      calendarStyle: const CalendarStyle(
        markersMaxCount: 3,
        todayDecoration:
        BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        selectedDecoration:
        BoxDecoration(color: Color(0xFFCCA242), shape: BoxShape.circle),
        defaultTextStyle: TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.white70),
      ),
      headerStyle: const HeaderStyle(
        titleTextStyle: TextStyle(color: Colors.white),
        formatButtonVisible: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (ctx, day, events) {
          if (events.isEmpty) return const SizedBox();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: events.take(3).map((e) {
              final r = e as Reminder;
              Color dotColor;
              switch (r.difficulty) {
                case 'Difícil':
                  dotColor = Colors.red;
                  break;
                case 'Media':
                  dotColor = Colors.amber;
                  break;
                default:
                  dotColor = Colors.green;
              }
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// Construye la vista semanal del horario con materias y recordatorios
  Widget _buildWeekly() {
    final startOfWeek =
    _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final hours = List.generate(13, (i) => 8 + i);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Semana ${startOfWeek.day}/${startOfWeek.month} – ${endOfWeek.day}/${endOfWeek.month}',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: Colors.white24),
              defaultColumnWidth: const FixedColumnWidth(100),
              children: [
                TableRow(children: [
                  const SizedBox(height: 40),
                  for (var d in days)
                    Center(
                      child: Text(
                        '${_weekdayNames[d.weekday - 1]}\n${d.day}/${d.month}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ]),
                for (var h in hours)
                  TableRow(children: [
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      color: Colors.blueGrey.shade900,
                      child:
                      Text('$h:00', style: const TextStyle(color: Colors.white70)),
                    ),
                    for (var d in days) _buildCellForDayHour(d, h),
                  ]),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  /// Construye cada celda del horario semanal, permite múltiples materias y borrado
  Widget _buildCellForDayHour(DateTime day, int hour) {
    final clsList = _classes.where((c) {
      return c.daysOfWeek.contains(day.weekday) &&
          hour >= c.start.hour &&
          hour < c.end.hour;
    }).toList();

    if (clsList.isEmpty) return const SizedBox();

    // Si hay más de una materia, las muestra en fila
    if (clsList.length > 1) {
      return Row(
        children: clsList.map((c) {
          return Expanded(
            child: GestureDetector(
              onLongPress: () => _confirmDeleteClass(c),
              child: Container(
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.all(4),
                height: 60,
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.subject,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Una sola materia: con tooltip y borrado por pulsación larga
    final c0 = clsList.first;
    return GestureDetector(
      onLongPress: () => _confirmDeleteClass(c0),
      child: Tooltip(
        message:
        '${c0.professor ?? ''}${c0.room != null ? ' • ${c0.room}' : ''}',
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c0.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            c0.subject,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A243C),
        appBar: AppBar(
          backgroundColor: const Color(0xFFCCA242),
          title: const Text('Calendario & Horario',
              style: TextStyle(color: Colors.black)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'Calendario'),
              Tab(icon: Icon(Icons.view_week), text: 'Horario'),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFCCA242),
          onPressed: _onAddPressed,
          child: const Icon(Icons.add, color: Colors.black),
        ),
        body: TabBarView(children: [
          Column(children: [
            Expanded(flex: 2, child: _buildMonthly()),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: ListView(
                children: _reminders
                    .where((r) => isSameDay(r.dateTime, _selectedDay))
                    .map((r) {
                  Color iconCol = r.difficulty == 'Difícil'
                      ? Colors.red
                      : r.difficulty == 'Media'
                      ? Colors.amber
                      : Colors.green;
                  return ListTile(
                    leading: Icon(Icons.notifications, color: iconCol),
                    title: Text(r.title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${r.subject} · ${r.category}',
                        style: const TextStyle(color: Colors.white70)),
                    onTap: () => _showEntryDialog(isReminder: true, rem: r),
                    onLongPress: () {
                      setState(() {
                        _reminders.remove(r);
                        _saveReminders();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ]),
          _buildWeekly(),
        ]),
      ),
    );
  }
}
