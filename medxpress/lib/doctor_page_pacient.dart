import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Doctorpage extends StatelessWidget {
  const Doctorpage({super.key});

  @override
  Widget build(BuildContext context) {
    final LatLng rijekaCenter = LatLng(45.3271, 14.4422);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokacija'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(255, 46, 138, 214),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: rijekaCenter,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.medxpress',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 60,
                height: 60,
                point: rijekaCenter,
                child:
                    const Icon(Icons.location_pin, size: 40, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
