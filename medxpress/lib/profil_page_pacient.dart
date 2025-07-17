import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'login_page.dart';

class ProfilPagePacient extends StatelessWidget {
  final String ime;
  final String prezime;

  const ProfilPagePacient({
    super.key,
    required this.ime,
    required this.prezime,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
            const SizedBox(height: 40),
            const Divider(),
            SwitchListTile(
              title: const Text("Tamna tema"),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              secondary: const Icon(Icons.brightness_6),
            ),
            const SizedBox(height: 20),
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
