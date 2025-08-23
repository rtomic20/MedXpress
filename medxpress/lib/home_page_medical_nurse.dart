import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'profile_page_medical_nurse.dart';
import 'chat_list_page.dart';
import 'helpers/api_config.dart';

import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;

class HomePageMedicalNurse extends StatefulWidget {
  final String ime;
  final String prezime;

  /// Ime doktora (za header)
  final String doktor;

  /// ID sestre (u starom kodu se zvao pacijentId – ovdje je to sestra_id)
  final int pacijentId;

  /// Korisnički ID (Korisnik.pk) – potreban za profil/izmjene lozinke i imena
  final int korisnikId;

  /// Opcionalno: ID doktora (ako ga proslijediš iz login odgovora)
  final int? doktorId;

  const HomePageMedicalNurse({
    super.key,
    required this.ime,
    required this.prezime,
    required this.doktor,
    required this.pacijentId,
    required this.korisnikId,
    this.doktorId,
  });

  @override
  State<HomePageMedicalNurse> createState() => _HomePageMedicalNurseState();
}

class _HomePageMedicalNurseState extends State<HomePageMedicalNurse> {
  DateTime _selectedDate = DateTime.now();

  TimeOfDay _startTod = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTod = const TimeOfDay(hour: 9, minute: 30);

  // Lista pacijenata izvedena iz razgovora
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;

  // Kalendar
  final Set<DateTime> _busyDates = {}; // set datuma s terminima
  final List<Map<String, dynamic>> _appointments = []; // svi dohvaćeni termini

  @override
  void initState() {
    super.initState();
    _fetchPatientsFromConversations();
    _fetchAppointments();
  }

  // ===== Helpers =====
  DateTime _ymd(DateTime d) => DateTime(d.year, d.month, d.day);
  String _hm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic>? _extractPatient(Map<String, dynamic> conv) {
    // 1) ako response već sadrži polja pacijenta
    final pid = conv['pacijent'] as int?;
    final ime = (conv['pacijent_ime'] ?? '').toString().trim();
    final prezime = (conv['pacijent_prezime'] ?? '').toString().trim();
    if (pid != null && (ime.isNotEmpty || prezime.isNotEmpty)) {
      return {'korisnik_id': pid, 'ime': ime, 'prezime': prezime};
    }
    // 2) iz participants
    final partsRaw = conv['participants'];
    if (partsRaw is List) {
      for (final pAny in partsRaw) {
        final p = (pAny as Map).map((k, v) => MapEntry(k.toString(), v));
        final roleStr =
            (p['uloga'] ?? p['role'] ?? '').toString().toLowerCase();
        if (roleStr.contains('pacijent')) {
          final kid = (p['korisnik_id'] ?? p['user_id']) as int?;
          final pi = (p['ime'] ?? '').toString().trim();
          final pp = (p['prezime'] ?? '').toString().trim();
          if (kid != null && (pi.isNotEmpty || pp.isNotEmpty)) {
            return {'korisnik_id': kid, 'ime': pi, 'prezime': pp};
          }
        }
      }
    }
    // 3) fallback – ako ima smisla iz naslova
    final title = (conv['title'] ?? '').toString().trim();
    if (pid != null && title.isNotEmpty && title.toLowerCase() != 'nepoznato') {
      final parts = title.split(RegExp(r'\s+'));
      String tIme = '', tPrez = '';
      if (parts.length >= 2) {
        tIme = parts.first;
        tPrez = parts.sublist(1).join(' ');
      } else {
        tIme = title;
      }
      return {'korisnik_id': pid, 'ime': tIme, 'prezime': tPrez};
    }
    return null;
  }

  Future<void> _fetchPatientsFromConversations() async {
    try {
      final uri = Uri.parse('$baseUrl/conversations/');
      final res = await http.get(uri);
      if (res.statusCode != 200) return;

      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;

      // filtriraj konverzacije gdje je OVA sestra
      final convs = list
          .map((e) => (e as Map).cast<String, dynamic>())
          .where((c) => (c['sestra'] as int?) == widget.pacijentId);

      final uniq = <int, Map<String, dynamic>>{};
      for (final conv in convs) {
        final p = _extractPatient(conv);
        if (p == null) continue;
        uniq[p['korisnik_id'] as int] = p;
      }

      final items = uniq.values.toList();
      setState(() {
        _patients = items;
        if (items.length == 1) _selectedPatient = items.first;
      });
    } catch (e) {
      debugPrint('Greška pacijenata (sestra): $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      // backend filter: sestra_id
      final uri = Uri.parse('$baseUrl/appointments/')
          .replace(queryParameters: {'sestra_id': '${widget.pacijentId}'});
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint('GET /appointments/ (sestra) => ${res.statusCode}');
        return;
      }

      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final items = data.cast<Map<String, dynamic>>();

      final setDates = <DateTime>{};
      for (final a in items) {
        final sIso = (a['start_time'] ?? a['start'])?.toString();
        if (sIso == null || sIso.isEmpty) continue;
        final s = DateTime.tryParse(sIso);
        if (s == null) continue;
        setDates.add(_ymd(s));
      }

      setState(() {
        _appointments
          ..clear()
          ..addAll(items);
        _busyDates
          ..clear()
          ..addAll(setDates);
      });
    } catch (e) {
      debugPrint('Greška termina (sestra): $e');
    }
  }

  Future<void> _pickStart() async {
    final picked =
        await showTimePicker(context: context, initialTime: _startTod);
    if (picked != null) setState(() => _startTod = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _endTod);
    if (picked != null) setState(() => _endTod = picked);
  }

  Future<DateTime?> _pickDate(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return picked;
  }

  Future<void> _openAddAppointmentDialog() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Dodaj termin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Odabrano: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPatient,
                  decoration:
                      const InputDecoration(labelText: 'Odaberi pacijenta'),
                  items: _patients
                      .map((p) => DropdownMenuItem<Map<String, dynamic>>(
                            value: p,
                            child: Text('${p['ime']} ${p['prezime']}'.trim()),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPatient = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStart,
                        child: Text('Početak: ${_startTod.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEnd,
                        child: Text('Kraj: ${_endTod.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Naslov (opcionalno)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Napomena (opcionalno)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Odustani')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Spremi')),
          ],
        );
      },
    );

    if (ok != true) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite pacijenta.')),
      );
      return;
    }

    await _createAppointment(
      pacijentId: _selectedPatient!['korisnik_id'] as int,
      sestraId: widget.pacijentId,
      doktorId: widget.doktorId, // može biti null
      date: _selectedDate,
      start: _startTod,
      end: _endTod,
      title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
  }

  Future<void> _openEditAppointmentDialog(Map<String, dynamic> appt) async {
    final s = DateTime.parse(appt['start_time'].toString());
    final e = DateTime.parse(appt['end_time'].toString());
    DateTime pickedDate = _ymd(s);
    TimeOfDay startTod = TimeOfDay(hour: s.hour, minute: s.minute);
    TimeOfDay endTod = TimeOfDay(hour: e.hour, minute: e.minute);

    final titleCtrl =
        TextEditingController(text: (appt['title'] ?? '').toString());
    final noteCtrl =
        TextEditingController(text: (appt['note'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uredi termin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await _pickDate(pickedDate);
                  if (d != null) setState(() => pickedDate = d);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                    'Datum: ${pickedDate.day}.${pickedDate.month}.${pickedDate.year}.'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(
                            context: context, initialTime: startTod);
                        if (p != null) setState(() => startTod = p);
                      },
                      child: Text('Početak: ${startTod.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final p = await showTimePicker(
                            context: context, initialTime: endTod);
                        if (p != null) setState(() => endTod = p);
                      },
                      child: Text('Kraj: ${endTod.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Naslov'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Napomena'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Spremi')),
        ],
      ),
    );

    if (ok != true) return;

    await _updateAppointment(
      id: appt['id'] as int,
      date: pickedDate,
      start: startTod,
      end: endTod,
      title: titleCtrl.text.trim(),
      note: noteCtrl.text.trim(),
    );
  }

  Future<void> _confirmAndDeleteAppointment(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši termin'),
        content: const Text('Jeste li sigurni da želite obrisati ovaj termin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ne')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Da, obriši')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteAppointment(id);
    }
  }

  Future<void> _createAppointment({
    required int pacijentId,
    required int sestraId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    int? doktorId,
    String? title,
    String? note,
  }) async {
    try {
      final startDt =
          DateTime(date.year, date.month, date.day, start.hour, start.minute);
      final endDt =
          DateTime(date.year, date.month, date.day, end.hour, end.minute);

      final body = <String, dynamic>{
        'pacijent': pacijentId,
        'sestra': sestraId,
        'start_time': startDt.toIso8601String(),
        'end_time': endDt.toIso8601String(),
        if (doktorId != null) 'doktor': doktorId,
        if (title != null) 'title': title,
        if (note != null) 'note': note,
      };

      final res = await http.post(
        Uri.parse('$baseUrl/appointments/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin uspješno dodan.')),
        );
        await _fetchAppointments();
      } else {
        final txt = utf8.decode(res.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška (${res.statusCode}): $txt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri spremanju termina: $e')),
      );
    }
  }

  Future<void> _updateAppointment({
    required int id,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    String? title,
    String? note,
  }) async {
    try {
      final startDt =
          DateTime(date.year, date.month, date.day, start.hour, start.minute);
      final endDt =
          DateTime(date.year, date.month, date.day, end.hour, end.minute);

      final body = <String, dynamic>{
        'start_time': startDt.toIso8601String(),
        'end_time': endDt.toIso8601String(),
      };
      if (title != null) body['title'] = title;
      if (note != null) body['note'] = note;

      final res = await http.put(
        Uri.parse('$baseUrl/appointments/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin je ažuriran.')),
        );
        await _fetchAppointments();
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        final txt = utf8.decode(res.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška (${res.statusCode}): $txt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri ažuriranju: $e')),
      );
    }
  }

  Future<void> _deleteAppointment(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/appointments/$id/'));
      if (res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin je obrisan.')),
        );
        await _fetchAppointments();
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        final txt = utf8.decode(res.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška (${res.statusCode}): $txt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri brisanju: $e')),
      );
    }
  }

  void _showDayAppointments(DateTime date) {
    final day = _ymd(date);
    final items = _appointments.where((a) {
      final sIso = (a['start_time'] ?? a['start'])?.toString();
      final s = sIso != null ? DateTime.tryParse(sIso) : null;
      return s != null && _ymd(s) == day;
    }).toList();

    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final a = items[i];
            final s = DateTime.parse(a['start_time']);
            final e = DateTime.parse(a['end_time']);
            final t = (a['title'] ?? '').toString();
            final label = t.isNotEmpty ? t : 'Termin';
            final note = (a['note'] ?? '').toString();
            final docIme = (a['doktor_ime'] ?? '').toString();

            return ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(label),
              subtitle: Text(
                '${_hm(s)} – ${_hm(e)}'
                '${docIme.isNotEmpty ? '\n$docIme' : ''}'
                '${note.isNotEmpty ? '\n$note' : ''}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Uredi',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openEditAppointmentDialog(a),
                  ),
                  IconButton(
                    tooltip: 'Obriši',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _confirmAndDeleteAppointment(a['id'] as int),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== UI (isti stil kao kod doktora) ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F6FF), // svijetlo plava pozadina
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dobro došli, ${widget.ime} ${widget.prezime}!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: CalendarCarousel(
                    locale: 'hr',
                    firstDayOfWeek: 1,
                    height: 420.0,
                    weekFormat: false,
                    showOnlyCurrentMonthDate: true,
                    customGridViewPhysics: const BouncingScrollPhysics(),
                    selectedDateTime: _selectedDate,
                    customDayBuilder: (
                      bool isSelectable,
                      int index,
                      bool isSelectedDay,
                      bool isToday,
                      bool isPrevMonthDay,
                      TextStyle textStyle,
                      bool isNextMonthDay,
                      bool isThisMonthDay,
                      DateTime day,
                    ) {
                      final hasAppt = _busyDates.contains(_ymd(day));
                      if (!hasAppt) return null;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(child: Text('${day.day}', style: textStyle)),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    onDayPressed: (date, events) {
                      setState(() => _selectedDate = date);
                      _showDayAppointments(date);
                    },
                    showHeader: true,
                    headerTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    headerMargin: const EdgeInsets.symmetric(vertical: 10),
                    weekdayTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4F59),
                    ),
                    daysTextStyle: const TextStyle(
                      color: Color(0xFF30343A),
                      fontSize: 14,
                    ),
                    daysHaveCircularBorder: true,
                    dayButtonColor: Colors.transparent,
                    thisMonthDayBorderColor: const Color(0xFFCBD5E1),
                    prevMonthDayBorderColor: Colors.transparent,
                    nextMonthDayBorderColor: Colors.transparent,
                    todayButtonColor: const Color(0xFFE8F1FF),
                    todayBorderColor: const Color(0xFFE8F1FF),
                    selectedDayButtonColor: const Color(0xFF1A73E8),
                    selectedDayBorderColor: const Color(0xFF1A73E8),
                    selectedDayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    weekendTextStyle: const TextStyle(color: Color(0xFFDE3B3B)),
                    inactiveDaysTextStyle:
                        const TextStyle(color: Color(0xFF9AA3AE)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Odabrano: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4A4F59),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openAddAppointmentDialog,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Dodaj termin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDE0FF),
                      foregroundColor: const Color(0xFF4338CA),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Odaberi datum u kalendaru i spremi termin za pacijenta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4D9B),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF808080).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            )
          ],
        ),
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(
              context,
              'assets/images/razgovori_doktor_medicinska_sestra.png',
              'Poruke',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatListPage(
                    pacijentId: widget.pacijentId,
                    filterRole: 'pacijent_sestra',
                    title: 'Poruke',
                  ),
                ),
              ),
            ),
            _navItem(
              context,
              'assets/images/doktor_medicinska_sestra_profil.png',
              'Profil',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilPageMedicalNurse(
                    korisnikId: widget.korisnikId, // za promjenu lozinke/imenA
                    ime: widget.ime,
                    prezime: widget.prezime,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String imagePath,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            child: Image.asset(
              imagePath,
              width: 53,
              height: 53,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
