import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helpers/api_config.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';

class ProfilPageMedicalNurse extends StatefulWidget {
  final int korisnikId; // <-- DODANO: potreban za API pozive
  final String ime;
  final String prezime;

  const ProfilPageMedicalNurse({
    super.key,
    required this.korisnikId,
    required this.ime,
    required this.prezime,
  });

  @override
  State<ProfilPageMedicalNurse> createState() => _ProfilPageMedicalNurseState();
}

class _ProfilPageMedicalNurseState extends State<ProfilPageMedicalNurse> {
  late String _ime;
  late String _prezime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ime = widget.ime;
    _prezime = widget.prezime;
    _fetchProfile();
  }

  String _initials(String name, String surname) {
    final i = name.isNotEmpty ? name[0] : '';
    final p = surname.isNotEmpty ? surname[0] : '';
    return (i + p).toUpperCase();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("$baseUrl/korisnici/${widget.korisnikId}/");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (!mounted) return;
        setState(() {
          _ime = (data["ime"] ?? _ime).toString();
          _prezime = (data["prezime"] ?? _prezime).toString();
        });
      } else {
        _showSnack("Greška ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      _showSnack("Greška mreže: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditProfileSheet() async {
    final imeCtrl = TextEditingController(text: _ime);
    final prezimeCtrl = TextEditingController(text: _prezime);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setBS) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;
              setBS(() => saving = true);
              try {
                final url =
                    Uri.parse("$baseUrl/korisnici/${widget.korisnikId}/");
                final body = jsonEncode({
                  "ime": imeCtrl.text.trim(),
                  "prezime": prezimeCtrl.text.trim(),
                });
                final res = await http.patch(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: body,
                );

                if (!mounted) return;
                if (res.statusCode == 200) {
                  setState(() {
                    _ime = imeCtrl.text.trim();
                    _prezime = prezimeCtrl.text.trim();
                  });
                  Navigator.pop(context);
                  _showSnack("Profil ažuriran");
                } else {
                  _showSnack("Greška ${res.statusCode}: ${res.body}");
                }
              } catch (e) {
                _showSnack("Greška mreže: $e");
              } finally {
                setBS(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      "Uredi profil",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: imeCtrl,
                      decoration: const InputDecoration(labelText: "Ime"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Obavezno" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: prezimeCtrl,
                      decoration: const InputDecoration(labelText: "Prezime"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Obavezno" : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.save),
                        label: Text(saving ? "Spremam..." : "Spremi"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    // bitno: varijable izvan buildera = rade sa setState iz StatefulBuildera
    bool obscureOld = true;
    bool obscureNew = true;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setD) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;
              setD(() => saving = true);
              try {
                final url = Uri.parse(
                    "$baseUrl/korisnici/${widget.korisnikId}/change-password");
                final res = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "old_password": oldCtrl.text,
                    "new_password": newCtrl.text,
                  }),
                );
                if (!mounted) return;

                if (res.statusCode == 200) {
                  Navigator.pop(context);
                  _showSnack("Lozinka promijenjena");
                } else {
                  _showSnack("Greška ${res.statusCode}: ${res.body}");
                }
              } catch (e) {
                _showSnack("Greška mreže: $e");
              } finally {
                setD(() => saving = false);
              }
            }

            return AlertDialog(
              title: const Text("Promijeni lozinku"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldCtrl,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: "Stara lozinka",
                        suffixIcon: IconButton(
                          onPressed: () => setD(() => obscureOld = !obscureOld),
                          icon: Icon(obscureOld
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Obavezno" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Nova lozinka",
                        suffixIcon: IconButton(
                          onPressed: () => setD(() => obscureNew = !obscureNew),
                          icon: Icon(obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Obavezno";
                        if (v.length < 8) return "Minimalno 8 znakova";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text("Odustani"),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.lock),
                  label: Text(saving ? "Spremam..." : "Promijeni"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Moj profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          _initials(_ime, _prezime),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "$_ime $_prezime",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text("Uredi profil"),
                    subtitle: const Text("Ažuriraj ime i prezime"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openEditProfileSheet,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Promijeni lozinku"),
                    subtitle: const Text("Ažuriraj svoju lozinku"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openChangePasswordDialog,
                  ),
                  const Spacer(),
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
