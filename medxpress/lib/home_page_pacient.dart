import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helpers/api_config.dart'; // baseUrl
import 'doctor_page_pacient.dart';
import 'profil_page_pacient.dart';
import 'chat_list_page.dart';

import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;

class HomePagePacient extends StatefulWidget {
  final int pacijentId;
  final String ime;
  final String prezime;
  final int korisnikId;

  const HomePagePacient({
    super.key,
    required this.pacijentId,
    required this.ime,
    required this.prezime,
    required this.korisnikId,
  });

  @override
  State<HomePagePacient> createState() => _HomePagePacientState();
}

class _HomePagePacientState extends State<HomePagePacient> {
  DateTime _selectedDate = DateTime.now();

  // datum (00:00) -> lista termina
  final Map<DateTime, List<_Appointment>> _byDate = {};
  final Set<String> _fetchedMonths = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMonth(_selectedDate);
  }

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  String _monthKey(DateTime x) =>
      '${x.year}-${x.month.toString().padLeft(2, '0')}';

  Future<void> _fetchMonth(DateTime anchor) async {
    final key = _monthKey(anchor);
    if (_fetchedMonths.contains(key)) return;

    final first = DateTime(anchor.year, anchor.month, 1);
    final last = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59);

    final uri = Uri.parse(
      '$baseUrl/appointments/?pacijent_id=${widget.pacijentId}'
      '&from=${first.toIso8601String()}'
      '&to=${last.toIso8601String()}',
    );

    try {
      final res =
          await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode != 200) {
        setState(() => _error = 'Greška ${res.statusCode}');
        return;
      }
      final data = json.decode(res.body);
      if (data is! List) return;

      final monthMap = <DateTime, List<_Appointment>>{};
      for (final e in data) {
        final a = _Appointment.fromJson(e as Map<String, dynamic>);
        // termin može trajati kroz više dana
        var cur = _d(a.start);
        final endDay = _d(a.end);
        while (!cur.isAfter(endDay)) {
          monthMap.putIfAbsent(cur, () => []).add(a);
          cur = cur.add(const Duration(days: 1));
        }
      }

      setState(() {
        monthMap.forEach((k, v) {
          final list = _byDate.putIfAbsent(k, () => []);
          list.addAll(v);
          list.sort((a, b) => a.start.compareTo(b.start));
        });
        _fetchedMonths.add(key);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  bool _hasAppt(DateTime day) => _byDate.containsKey(_d(day));
  List<_Appointment> get _selectedDayAppts =>
      _byDate[_d(_selectedDate)] ?? const [];

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchedMonths.clear();
            _byDate.clear();
            await _fetchMonth(_selectedDate);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dobro došao, ${widget.ime} ${widget.prezime}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // KALENDAR
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      height: 420,
                      weekFormat: false,
                      showOnlyCurrentMonthDate: true,
                      customGridViewPhysics: const BouncingScrollPhysics(),
                      selectedDateTime: _selectedDate,
                      onDayPressed: (date, _) =>
                          setState(() => _selectedDate = date),
                      onCalendarChanged: (d) => _fetchMonth(d),

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

                      // čisti kružići, dot poravnat
                      daysHaveCircularBorder: false,
                      dayButtonColor: Colors.transparent,
                      thisMonthDayBorderColor: Colors.transparent,
                      prevMonthDayBorderColor: Colors.transparent,
                      nextMonthDayBorderColor: Colors.transparent,
                      todayButtonColor: Colors.transparent,
                      todayBorderColor: Colors.transparent,
                      selectedDayButtonColor: Colors.transparent,
                      selectedDayBorderColor: Colors.transparent,
                      weekendTextStyle:
                          const TextStyle(color: Color(0xFFDE3B3B)),
                      inactiveDaysTextStyle:
                          const TextStyle(color: Color(0xFF9AA3AE)),
                      daysTextStyle: const TextStyle(
                          color: Color(0xFF30343A), fontSize: 14),

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
                        final selected = _d(day) == _d(_selectedDate);
                        final has = _hasAppt(day);

                        return SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (selected)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1A73E8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : (isThisMonthDay
                                          ? const Color(0xFF30343A)
                                          : const Color(0xFF9AA3AE)),
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Align(
                                alignment: const Alignment(0, 0.85),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 120),
                                  opacity: has ? 1 : 0,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF1A73E8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                  const SizedBox(height: 8),

                  // Lista termina ispod
                  if (_selectedDayAppts.isEmpty)
                    const Text(
                      'Nema termina za odabrani dan.',
                      textAlign: TextAlign.center,
                    )
                  else
                    Column(
                      children: _selectedDayAppts.map((a) {
                        final time =
                            '${_fmtTime(a.start)} - ${_fmtTime(a.end)}';

                        final doc = a.doctorName?.isNotEmpty == true
                            ? a.doctorName!
                            : (a.doctorId != null
                                ? 'Doktor ID: ${a.doctorId}'
                                : null);

                        final nurse = a.nurseName?.isNotEmpty == true
                            ? a.nurseName!
                            : (a.nurseId != null
                                ? 'Sestra ID: ${a.nurseId}'
                                : null);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title.isNotEmpty ? a.title : 'Termin',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    if (doc != null)
                                      Text(doc,
                                          style: const TextStyle(
                                              color: Color(0xFF4A4F59))),
                                    if (nurse != null)
                                      Text(nurse,
                                          style: const TextStyle(
                                              color: Color(0xFF4A4F59))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(time,
                                  style: const TextStyle(
                                      color: Color(0xFF4A4F59))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),

      // Bottom nav
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4D9B),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
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
            // PRETRAŽIVANJE
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Doctorpage(
                          pacijentId: widget.pacijentId,
                          pacijentIme: widget.ime,
                          pacijentPrezime: widget.prezime,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset(
                        'assets/images/pretrazivanje_doktora_opcenito.png',
                        fit: BoxFit.cover),
                  ),
                ),
                const Text('Pretraživanje',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            // DOKTOR CHAT
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatListPage(
                          pacijentId: widget.pacijentId,
                          filterRole: 'doktor',
                          title: 'Razgovori s liječnikom',
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset('assets/images/doktor_korisnik.png',
                        fit: BoxFit.cover),
                  ),
                ),
                const Text('Doktor',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            // SESTRA CHAT
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatListPage(
                          pacijentId: widget.pacijentId,
                          filterRole: 'sestra',
                          title: 'Razgovori sa sestrom',
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset(
                        'assets/images/medicinska_sestra_korisnik.png',
                        fit: BoxFit.cover),
                  ),
                ),
                const Text('Sestra',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            // PROFIL
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilPagePacient(
                          korisnikId: widget.korisnikId,
                          ime: widget.ime,
                          prezime: widget.prezime,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset('assets/images/korisnik_profil.png',
                        fit: BoxFit.cover),
                  ),
                ),
                const Text('Profil',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Appointment {
  final int id;
  final DateTime start;
  final DateTime end;
  final String title;
  final int? doctorId;
  final String? doctorName;
  final int? nurseId;
  final String? nurseName;

  _Appointment({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    this.doctorId,
    this.doctorName,
    this.nurseId,
    this.nurseName,
  });

  factory _Appointment.fromJson(Map<String, dynamic> j) {
    final start = DateTime.parse(j['start_time'].toString()).toLocal();
    final end = DateTime.parse(j['end_time'].toString()).toLocal();
    final dn = (j['doktor_ime'] ?? j['doctor_name'] ?? '').toString();
    final sn = (j['sestra_ime'] ?? j['nurse_name'] ?? '').toString();

    return _Appointment(
      id: j['id'] as int,
      start: start,
      end: end,
      title: (j['title'] ?? '').toString(),
      doctorId: j['doktor'] as int?,
      doctorName: dn.isNotEmpty ? dn : null,
      nurseId: j['sestra'] as int?,
      nurseName: sn.isNotEmpty ? sn : null,
    );
  }
}
