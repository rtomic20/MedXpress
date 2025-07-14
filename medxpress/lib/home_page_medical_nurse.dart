import 'package:flutter/material.dart';

class HomePageMedicalNurse extends StatelessWidget {
  final String ime;
  final String prezime;
  final String doktor;

  const HomePageMedicalNurse({
    super.key,
    required this.ime,
    required this.prezime,
    required this.doktor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 115, 195),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dobro došli, $ime $prezime!',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Vaš doktor: $doktor',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
            _buildNavItemImage(
              context,
              'assets/images/kalendar_opcenito.png',
              'Kalendar',
              () {
                print("Kalendar kliknut");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => KalendarPage()));
              },
            ),
            _buildNavItemImage(
              context,
              'assets/images/razgovori_doktor_medicinska_sestra.png',
              'Razgovor',
              () {
                print("Razgovor kliknut");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage()));
              },
            ),
            _buildNavItemImage(
              context,
              'assets/images/doktor_medicinska_sestra_profil.png',
              'Profil',
              () {
                print("Profil kliknut");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemImage(BuildContext context, String imagePath,
      String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            child: Image.asset(
              imagePath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
