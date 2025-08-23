import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/api_config.dart';
import '../helpers/chatservice.dart';
import 'chat_page.dart';

class Doctorpage extends StatefulWidget {
  const Doctorpage({
    super.key,
    required this.pacijentId,
    required this.pacijentIme,
    required this.pacijentPrezime,
  });

  final int pacijentId;
  final String pacijentIme;
  final String pacijentPrezime;

  @override
  State<Doctorpage> createState() => _DoctorpageState();
}

class _DoctorpageState extends State<Doctorpage> {
  final LatLng _center = LatLng(45.3271, 14.4422);
  late final MapController _mapController;
  double _mapZoom = 13.0;

  LatLng? _userLocation;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchInfirmaries();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    _mapController.move(_userLocation!, 15.0);
  }

  Future<void> _fetchInfirmaries() async {
    final String api = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final res = await http.get(Uri.parse('$api/infirmaries/'));
    if (res.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Greška ${res.statusCode} pri čitanju ambulanti')),
      );
      return;
    }

    final List list = jsonDecode(utf8.decode(res.bodyBytes));
    final List<Marker> ms = [];

    for (final inf in list) {
      final lat = double.tryParse(inf['lat'].toString()) ?? 0;
      final lng = double.tryParse(inf['long'].toString()) ?? 0;

      final String name = inf['Infirmary_name'] ?? 'Nepoznata ambulanta';
      final String doktorIme = inf['doktor_ime'] ?? 'Nepoznat';
      final String sestraIme = inf['sestra_ime'] ?? 'Nepoznata';

      final int? doktorId = inf['doktor'];
      final int? sestraId = inf['medicinska_sestra'];

      ms.add(
        Marker(
          width: 60,
          height: 60,
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () => _showInfirmaryDetails(
              name: name,
              doktorIme: doktorIme,
              sestraIme: sestraIme,
              doktorId: doktorId,
              sestraId: sestraId,
            ),
            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
          ),
        ),
      );
    }

    setState(() => _markers = ms);
  }

  void _showInfirmaryDetails({
    required String name,
    required String doktorIme,
    required String sestraIme,
    required int? doktorId,
    required int? sestraId,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Doktor: $doktorIme"),
            Text("Sestra: $sestraIme"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (doktorId == null)
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          try {
                            final convId = await ChatServiceHelper.instance
                                .startChatWithDoctor(
                              pacijentId: widget.pacijentId,
                              doktorId: doktorId!,
                              pacijentKorisnikId: widget.pacijentId,
                              doktorKorisnikId: doktorId!,
                              title: 'Pacijent–Doktor',
                            );

                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId: convId,
                                  senderKorisnikId: widget.pacijentId,
                                  title: 'Doktor $doktorIme',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Greška: $e')),
                            );
                          }
                        },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Kontakt doktor"),
                ),
                ElevatedButton.icon(
                  onPressed: (sestraId == null)
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          try {
                            final convId = await ChatServiceHelper.instance
                                .startChatWithNurse(
                              pacijentId: widget.pacijentId,
                              sestraId: sestraId!,
                              pacijentKorisnikId: widget.pacijentId,
                              sestraKorisnikId: sestraId!,
                              title: 'Pacijent–Sestra',
                            );

                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId: convId,
                                  senderKorisnikId: widget.pacijentId,
                                  title: 'Sestra $sestraIme',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Greška: $e')),
                            );
                          }
                        },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Kontakt sestra"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokacija'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(255, 46, 138, 214),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _mapZoom,
              onPositionChanged: (pos, hasGesture) {
                _mapZoom = pos.zoom ?? _mapZoom;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.medxpress',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.circle,
                          color: Colors.blue, size: 15),
                    ),
                  ..._markers,
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: FloatingActionButton(
              heroTag: "centerUser",
              mini: true,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, _mapZoom);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Lokacija korisnika nije dostupna.")),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
