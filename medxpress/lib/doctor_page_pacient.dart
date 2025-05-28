import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Doctorpage extends StatefulWidget {
  const Doctorpage({super.key});

  @override
  State<Doctorpage> createState() => _DoctorpageState();
}

class _DoctorpageState extends State<Doctorpage> {
  late GoogleMapController mapController;

  final LatLng _rijekaCenter = const LatLng(45.3271, 14.4422);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _rijekaCenter,
          zoom: 13,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('rijeka'),
            position: _rijekaCenter,
            infoWindow: const InfoWindow(title: 'Rijeka'),
          ),
        },
      ),
    );
  }
}
