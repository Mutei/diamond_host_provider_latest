// Add these imports at the top of your edit_estate_screen.dart file:
import 'package:daimond_host_provider/private.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';
import '../screens/full_map_screen.dart';

// Replace YOUR_API_KEY with your actual API key.
final GoogleMapsGeocoding _geocoding =
    GoogleMapsGeocoding(apiKey: PrivateKeys.googleMapsApiKey);

// ----------------------------------------------------------------
// Create a widget to edit the estate location.
class EditLocationSection extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationChanged;

  const EditLocationSection({
    Key? key,
    required this.initialLocation,
    required this.onLocationChanged,
  }) : super(key: key);

  @override
  _EditLocationSectionState createState() => _EditLocationSectionState();
}

class _EditLocationSectionState extends State<EditLocationSection> {
  late LatLng _currentLocation;
  GoogleMapController? _mapController;
  final TextEditingController _locationSearchController =
      TextEditingController();
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _marker = Marker(
      markerId: const MarkerId('estate_location'),
      position: _currentLocation,
      infoWindow: const InfoWindow(title: "Estate Location"),
    );
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    try {
      final GeocodingResponse response =
          await _geocoding.searchByAddress(query);
      if (response.status == 'OK' && response.results.isNotEmpty) {
        final result = response.results.first;
        LatLng newLocation = LatLng(
          result.geometry.location.lat,
          result.geometry.location.lng,
        );
        setState(() {
          _currentLocation = newLocation;
          _marker = Marker(
            markerId: const MarkerId('estate_location'),
            position: newLocation,
            infoWindow: InfoWindow(title: query),
          );
        });
        widget.onLocationChanged(newLocation);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLocation, zoom: 16),
          ),
        );
      }
    } catch (e) {
      print("Error in location search: $e");
    }
  }

  void _onMapTapped(LatLng tappedLocation) {
    setState(() {
      _currentLocation = tappedLocation;
      _marker = Marker(
        markerId: const MarkerId('estate_location'),
        position: tappedLocation,
        infoWindow: const InfoWindow(),
      );
    });
    widget.onLocationChanged(tappedLocation);
  }

  Future<void> _openFullScreenMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMap(initialLocation: _currentLocation),
      ),
    );
    if (result != null && result is LatLng) {
      setState(() {
        _currentLocation = result;
        _marker = Marker(
          markerId: const MarkerId('estate_location'),
          position: result,
          infoWindow: const InfoWindow(title: "Estate Location"),
        );
      });
      widget.onLocationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentLocation, zoom: 16),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTapped,
              markers: _marker != null ? {_marker!} : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          // Search bar positioned at the top.
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _locationSearchController,
                decoration: InputDecoration(
                  hintText: getTranslated(context, "Search"),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        _searchLocation(_locationSearchController.text),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLocation,
              ),
            ),
          ),
          // Full screen button positioned at the bottom right.
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _openFullScreenMap,
              child: const Icon(
                Icons.fullscreen,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
