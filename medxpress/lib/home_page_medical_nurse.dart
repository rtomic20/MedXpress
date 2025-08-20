import 'package:flutter/material.dart';
import 'profile_page_medical_nurse.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dobro došli, $ime $prezime!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Vaš doktor: $doktor',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              'assets/images/razgovori_doktor_medicinska_sestra.png',
              'Razgovor',
              () {
                print("Razgovor kliknut");
              },
            ),
            _buildNavItemImage(
              context,
              'assets/images/doktor_medicinska_sestra_profil.png',
              'Profil',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilPageMedicalNurse(
                      ime: ime,
                      prezime: prezime,
                    ),
                  ),
                );
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
