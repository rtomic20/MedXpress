import 'package:flutter/material.dart';

class HomePageDoctor extends StatelessWidget {
  final String ime;
  final String prezime;

  const HomePageDoctor({
    super.key,
    required this.ime,
    required this.prezime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 115, 195),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Dobrodošli, dr. $ime $prezime!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
            _buildNavItemImage(
              context,
              'assets/images/kalendar_opcenito.png',
              'Kalendar',
              () {
                print("Kalendar kliknut");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorCalendarPage()));
              },
            ),
            _buildNavItemImage(
              context,
              'assets/images/razgovori_doktor_medicinska_sestra.png',
              'Poruke',
              () {
                print("Poruke kliknute");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesPage()));
              },
            ),
            _buildNavItemImage(
              context,
              'assets/images/doktor_medicinska_sestra_profil.png',
              'Profil',
              () {
                print("Profil kliknuti");
                // Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfilePage()));
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
              width: 53,
              height: 53,
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
