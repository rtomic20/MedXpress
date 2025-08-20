import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_page_pacient.dart';
import 'home_page_doctor.dart';
import 'home_page_medical_nurse.dart';
import 'sign_up.dart';
import '../helpers/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController korisnickoImeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _login() async {
    final korisnickoIme = korisnickoImeController.text.trim();
    final lozinka = passwordController.text;

    if (korisnickoIme.isEmpty || lozinka.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesite korisničko ime i lozinku.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('$baseUrl/login/');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "korisnicko_ime": korisnickoIme,
          "lozinka": lozinka,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        // Očekujemo da backend vrati ove ključeve:
        final int? id = (data['id'] as num?)?.toInt(); // korisnik/pacijent id
        final String ime = (data['ime'] ?? '').toString();
        final String prezime = (data['prezime'] ?? '').toString();
        final String uloga = (data['uloga'] ?? '').toString();
        final String doktorIme = (data['doktor_ime'] ?? '').toString();

        Widget odredisnaStranica;

        if (uloga == 'doktor') {
          // ostavljam tvoj postojeći konstruktor
          odredisnaStranica = HomePageDoctor(
            ime: ime,
            prezime: prezime,
          );
        } else if (uloga == 'sestra') {
          // ostavljam tvoj postojeći konstruktor
          odredisnaStranica = HomePageMedicalNurse(
            ime: ime,
            prezime: prezime,
            doktor: doktorIme,
          );
        } else {
          // pacijent – prosljeđujemo pacijentId
          if (id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Nedostaje ID korisnika u odgovoru.')),
            );
            setState(() => _loading = false);
            return;
          }
          odredisnaStranica = HomePagePacient(
            pacijentId: id,
            ime: ime,
            prezime: prezime,
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => odredisnaStranica),
        );
      } else {
        final body = utf8.decode(res.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Neuspješna prijava (${res.statusCode}).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 115, 195),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Dobro došli u MedXpress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Korisničko ime
                TextField(
                  controller: korisnickoImeController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Korisničko ime',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Lozinka
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Lozinka',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.lock, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 20),

                // Registracija
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUp()),
                    );
                  },
                  child: const Text(
                    'Nemate račun? Registrirajte se',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
