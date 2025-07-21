import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/api_config.dart';

class Doctorpage extends StatefulWidget {
  const Doctorpage({super.key});

  @override
  State<Doctorpage> createState() => _DoctorpageState();
}

class _DoctorpageState extends State<Doctorpage> {
  final LatLng _center = LatLng(45.3271, 14.4422);
  List<Marker> _markers = [];
  late MapController _mapController;
  double _mapZoom = 13.0;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchInfirmaries();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });

    _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
  }

  Future<void> _fetchInfirmaries() async {
    final response = await http.get(Uri.parse('$baseUrl/api/infirmaries'));

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      final List<Marker> newMarkers = [];

      for (var inf in data) {
        final lat = double.tryParse(inf['lat'].toString()) ?? 0;
        final lng = double.tryParse(inf['long'].toString()) ?? 0;
        final name = inf['Infirmary_name'] ?? 'Nepoznata ambulanta';
        final doktor = inf['doktor_ime'] ?? 'Nepoznat';
        final sestra = inf['sestra_ime'] ?? 'Nepoznata';

        newMarkers.add(
          Marker(
            width: 60,
            height: 60,
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () => _showInfirmaryDetails(name, doktor, sestra),
              child:
                  const Icon(Icons.location_pin, size: 40, color: Colors.red),
            ),
          ),
        );
      }

      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _showInfirmaryDetails(String name, String doktor, String sestra) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Doktor: $doktor"),
            Text("Sestra: $sestra"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: otvori ekran za kontakt doktora
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text("Kontakt doktor"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: otvori ekran za kontakt sestre
                  },
                  icon: const Icon(Icons.phone),
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
