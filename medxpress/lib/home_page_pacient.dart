import 'package:flutter/material.dart';
import 'doctor_page_pacient.dart';

class HomePagePacient extends StatelessWidget {
  final String ime;
  final String prezime;

  const HomePagePacient({super.key, required this.ime, required this.prezime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: Text(
          'Dobro došao, $ime $prezime!',
          style: const TextStyle(fontSize: 24),
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
                          builder: (context) => const Doctorpage()),
                    );
                  },
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: Image.asset(
                      'assets/images/kalendar_opcenito.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Kalendar',
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
                          builder: (context) => const Doctorpage()),
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
