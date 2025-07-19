import 'package:flutter/material.dart';
import 'doctor_page_pacient.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'profil_page_pacient.dart';

class HomePagePacient extends StatefulWidget {
  final String ime;
  final String prezime;

  const HomePagePacient({super.key, required this.ime, required this.prezime});

  @override
  State<HomePagePacient> createState() => _HomePagePacientState();
}

class _HomePagePacientState extends State<HomePagePacient> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Dobro došao, ${widget.ime} ${widget.prezime}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CalendarCarousel(
              onDayPressed: (date, events) {
                setState(() {
                  _selectedDate = date;
                });
              },
              selectedDateTime: _selectedDate,
              height: 400.0,
              showOnlyCurrentMonthDate: true,
              daysHaveCircularBorder: true,
              weekFormat: false,
              customGridViewPhysics: const BouncingScrollPhysics(),
              thisMonthDayBorderColor: Colors.grey,
              selectedDayButtonColor: Colors.blue,
              selectedDayBorderColor: Colors.white,
              todayButtonColor: Colors.lightBlue,
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(color: Colors.black),
              daysTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
              weekdayTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
              inactiveDaysTextStyle: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
          ],
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
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Doctorpage()),
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
