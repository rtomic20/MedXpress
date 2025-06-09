import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/api_config.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController ime = TextEditingController();
    final TextEditingController prezime = TextEditingController();
    final TextEditingController korisnickoIme = TextEditingController();
    final TextEditingController passwordUser = TextEditingController();
    final TextEditingController email = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(255, 46, 138, 214),
      ),
      backgroundColor: const Color.fromARGB(255, 29, 115, 195),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                'Prijava za aplikaciju MedXpress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: ime,
                style: const TextStyle(color: Colors.black),
                decoration: _buildInputDecoration('Vaše ime:'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Unesite ime' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: prezime,
                style: const TextStyle(color: Colors.black),
                decoration: _buildInputDecoration('Vaše prezime:'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Unesite prezime' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: email,
                style: const TextStyle(color: Colors.black),
                decoration: _buildInputDecoration('Vaš email:'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Unesite email' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: korisnickoIme,
                style: const TextStyle(color: Colors.black),
                decoration: _buildInputDecoration('Vaše korisničko ime:'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Unesite korisničko ime'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordUser,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: _buildInputDecoration('Vaša lozinka:'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Unesite lozinku' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final imeKorisnika = ime.text;
                    final prezimeKorisnika = prezime.text;
                    final korisnickoImeKorisnika = korisnickoIme.text;
                    final passwordKorisnika = passwordUser.text;
                    final emailKorisnika = email.text;

                    final url = Uri.parse('$baseUrl/login/');

                    final response = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "korisnik": {
                          "ime": imeKorisnika,
                          "prezime": prezimeKorisnika,
                          "email": emailKorisnika,
                          "korisnicko_ime": korisnickoImeKorisnika,
                          "lozinka_hash": passwordKorisnika
                        }
                      }),
                    );

                    if (response.statusCode == 201) {
                      print("✅ Registracija uspješna");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Registracija uspješna")),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    } else {
                      print("❌ Greška: ${response.statusCode}");
                      print(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Registracija neuspješna")),
                      );
                    }
                  }
                },
                child: const Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      errorStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
      ),
    );
  }
}
