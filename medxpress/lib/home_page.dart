import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50, // Svetlo plava pozadina
      body: Center(
        child: const Text(
          'Welcome to the Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4D9B), // Boja trake (tamno plava)
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3), // Senka iznad trake
            ),
          ],
        ),
        height: 100, // Povećana visina trake
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Razmak između elemenata
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Prva slika sa tekstom
            Column(
              mainAxisSize: MainAxisSize.min, // Ograničenje veličine kolone
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRect(
                  child: Image.asset(
                    'assets/images/simptomi.jpg',
                    width: 40, // Širina slike
                    height: 40, // Visina slike
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4), // Razmak između slike i teksta
                const Text(
                  'Simptomi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Nova slika "Doctor" sa tekstom
            Column(
              mainAxisSize: MainAxisSize.min, // Ograničenje veličine kolone
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRect(
                  child: Image.asset(
                    'assets/images/doctor.jpg', // Putanja do slike doktora
                    width: 40, // Širina slike
                    height: 40, // Visina slike
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4), // Razmak između slike i teksta
                const Text(
                  'Doctor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // kalendar
            Column(
              mainAxisSize: MainAxisSize.min, // Ograničenje veličine kolone
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRect(
                  child: Image.asset(
                    'assets/images/kalendar.jpg', // Putanja do slike kalendara
                    width: 40, // Širina slike
                    height: 40, // Visina slike
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4), // Razmak između slike i teksta
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
          ],
        ),
      ),
    );
  }
}
