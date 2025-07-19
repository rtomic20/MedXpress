import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'login_page.dart';

class ProfilPageMedicalNurse extends StatelessWidget {
  final String ime;
  final String prezime;

  const ProfilPageMedicalNurse({
    super.key,
    required this.ime,
    required this.prezime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Moj profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ime: $ime", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Prezime: $prezime", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            const Divider(),
            SwitchListTile(
              title: const Text("Tamna tema"),
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (_) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme();
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Odjava',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
