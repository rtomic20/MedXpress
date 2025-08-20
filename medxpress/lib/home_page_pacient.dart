import 'package:flutter/material.dart';
import 'doctor_page_pacient.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'profil_page_pacient.dart';
import 'chat_list_page.dart';

class HomePagePacient extends StatefulWidget {
  final int pacijentId;
  final String ime;
  final String prezime;

  const HomePagePacient({
    super.key,
    required this.pacijentId,
    required this.ime,
    required this.prezime,
  });

  @override
  State<HomePagePacient> createState() => _HomePagePacientState();
}

class _HomePagePacientState extends State<HomePagePacient> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Naslov
                Text(
                  'Dobro došao, ${widget.ime} ${widget.prezime}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Kartica s kalendarom
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
                    // UX
                    locale: 'hr',
                    firstDayOfWeek: 1,
                    height: 420.0,
                    weekFormat: false,
                    showOnlyCurrentMonthDate: true,
                    customGridViewPhysics: const BouncingScrollPhysics(),

                    // Odabir
                    selectedDateTime: _selectedDate,
                    onDayPressed: (date, events) {
                      setState(() => _selectedDate = date);
                    },

                    // Header mjeseca
                    showHeader: true,
                    headerTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    headerMargin: const EdgeInsets.symmetric(vertical: 10),

                    // Tipografija
                    weekdayTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4F59),
                    ),
                    daysTextStyle: const TextStyle(
                      color: Color(0xFF30343A),
                      fontSize: 14,
                    ),

                    // Obrubi i boje dana
                    daysHaveCircularBorder: true,
                    dayButtonColor: Colors.transparent,
                    thisMonthDayBorderColor: const Color(0xFFCBD5E1),
                    prevMonthDayBorderColor: Colors.transparent,
                    nextMonthDayBorderColor: Colors.transparent,

                    // Danas i odabrani
                    todayButtonColor: const Color(0xFFE8F1FF),
                    todayBorderColor: const Color(0xFFE8F1FF),
                    selectedDayButtonColor: const Color(0xFF1A73E8),
                    selectedDayBorderColor: const Color(0xFF1A73E8),
                    selectedDayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),

                    // Vikendi i neaktivni
                    weekendTextStyle: const TextStyle(color: Color(0xFFDE3B3B)),
                    inactiveDaysTextStyle:
                        const TextStyle(color: Color(0xFF9AA3AE)),
                  ),
                ),

                const SizedBox(height: 16),

                // Odabrani datum – informativno
                Text(
                  'Odabrano: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4A4F59),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // Bottom navigacija
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
            // Pretraživanje (karte + chat)
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
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Pretraživanje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                    child: Image.asset(
                      'assets/images/doktor_korisnik.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Doktor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

// Sestra – lista razgovora sa sestrama
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
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Sestra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Profil
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
                          ime: widget.ime,
                          prezime: widget.prezime,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset(
                      'assets/images/korisnik_profil.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
