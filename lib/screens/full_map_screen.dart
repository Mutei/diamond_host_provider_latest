import 'package:daimond_host_provider/private.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/geocoding.dart';

import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';

final GoogleMapsGeocoding _geocoding =
    GoogleMapsGeocoding(apiKey: PrivateKeys.googleMapsApiKey);

class FullScreenMap extends StatefulWidget {
  final LatLng initialLocation;

  const FullScreenMap({Key? key, required this.initialLocation})
      : super(key: key);

  @override
  _FullScreenMapState createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(getTranslated(context, "Select Location")),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.check),
      //       onPressed: () {
      //         Navigator.pop(context, _currentLocation);
      //       },
      //     )
      //   ],
      // ),
      appBar: ReusedAppBar(
        title: getTranslated(context, "Search"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _currentLocation);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
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
        ],
      ),
    );
  }
}
