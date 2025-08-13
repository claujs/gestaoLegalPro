import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AudienceEvent {
  final String title;
  final DateTime dateTime;
  final Color color;
  final bool push;
  final String local;
  final String observacoes;
  AudienceEvent({
    required this.title,
    required this.dateTime,
    required this.color,
    required this.push,
    required this.local,
    required this.observacoes,
  });
}

class ScheduleAudiencePage extends StatefulWidget {
  const ScheduleAudiencePage({super.key});
  static const route = '/agenda/audiencia';

  @override
  State<ScheduleAudiencePage> createState() => _ScheduleAudiencePageState();
}

class _ScheduleAudiencePageState extends State<ScheduleAudiencePage> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final _titleCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  TimeOfDay? _time = TimeOfDay.now();
  Color _color = Colors.blue;
  bool _push = true;

  final Map<DateTime, List<AudienceEvent>> _events = {};

  List<AudienceEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _addEvent() {
    if (_selectedDay == null || _titleCtrl.text.trim().isEmpty || _time == null)
      return;
    final dt = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _time!.hour,
      _time!.minute,
    );
    final ev = AudienceEvent(
      title: _titleCtrl.text.trim(),
      dateTime: dt,
      color: _color,
      push: _push,
      local: _localCtrl.text.trim(),
      observacoes: _obsCtrl.text.trim(),
    );
    final key = DateTime(dt.year, dt.month, dt.day);
    setState(() {
      _events.putIfAbsent(key, () => []).add(ev);
    });
    _titleCtrl.clear();
    _localCtrl.clear();
    _obsCtrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Audiência agendada')));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickColor() async {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    Color temp = _color;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Escolher cor do evento'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in colors)
                GestureDetector(
                  onTap: () => setLocal(() => temp = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: temp == c ? Colors.white : Colors.white70,
                        width: temp == c ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: temp == c
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _color = temp);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _localCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Audiência')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TableCalendar<AudienceEvent>(
                    locale: 'pt_BR',
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onFormatChanged: (f) => setState(() => _format = f),
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markerDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.4),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Eventos do dia',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._getEventsForDay(
                    _selectedDay ?? DateTime.now(),
                  ).map((e) => _eventTile(e)),
                  if (_getEventsForDay(_selectedDay ?? DateTime.now()).isEmpty)
                    const Text('Nenhum evento para este dia.'),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            color: Theme.of(context).dividerColor.withOpacity(.2),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nova audiência',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _localCtrl,
                    decoration: const InputDecoration(labelText: 'Local'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _time == null ? 'Selecionar' : _time!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickColor,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Cor do evento',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Alterar'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _push,
                              onChanged: (v) =>
                                  setState(() => _push = v ?? true),
                            ),
                            Expanded(
                              child: Tooltip(
                                message:
                                    'Marque para enviar uma notificação push do Processo Ágil para o app instalado no seu smartphone (se você estiver logado nele). Útil para lembrar da audiência.',
                                triggerMode: TooltipTriggerMode.longPress,
                                waitDuration: const Duration(milliseconds: 400),
                                child: const Text('Enviar push'),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Envia uma notificação push para o app Processo Ágil no seu celular avisando sobre esta audiência.',
                              child: const Icon(Icons.info_outline, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _obsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addEvent,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Agendar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(AudienceEvent e) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: e.color,
          child: const Icon(Icons.mic, color: Colors.white, size: 16),
        ),
        title: Text(e.title),
        subtitle: Text(
          '${TimeOfDay.fromDateTime(e.dateTime).format(context)}  •  ${e.local.isEmpty ? 'Sem local' : e.local}',
        ),
        trailing: e.push
            ? const Icon(Icons.notifications_active_outlined, size: 18)
            : null,
      ),
    );
  }
}
