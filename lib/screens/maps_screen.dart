import 'package:daimond_host_provider/private.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/geocoding.dart';

import '../utils/failure_dialogue.dart';
import 'add_image_screen.dart';
import 'additional_facility_screen.dart';

// Instantiate the GoogleMapsGeocoding with your API key.
final GoogleMapsGeocoding _geocoding =
    GoogleMapsGeocoding(apiKey: PrivateKeys.googleMapsApiKey);

class MapsScreen extends StatefulWidget {
  final String id;
  final String typeEstate;

  MapsScreen({super.key, required this.id, required this.typeEstate});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  /// This is the *actual* estate location that the user will set.
  /// By default, it's in San Francisco.
  /// If the user never changes this, we'll know they didn't pick a location.
  LatLng latLng = const LatLng(24.662469396093744, 46.72888085246086);

  /// This marker corresponds to `latLng` (the estate location).
  Marker marker = const Marker(
    markerId: MarkerId('marker_1'),
    position: LatLng(24.662469396093744, 46.72888085246086),
    infoWindow: InfoWindow(),
  );

  /// We'll fetch the user's location in the background, storing it here
  /// only to animate the camera. We do *not* use this to set the marker.
  LatLng? userCenter;

  DatabaseReference ref = FirebaseDatabase.instance.ref("App").child("Estate");
  GoogleMapController? _controller;
  TextEditingController _searchController = TextEditingController();

  // List to store search results for suggestions.
  List<GeocodingResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Fetch the user's location (quick fallback with last known, then high-accuracy).
  /// Store it in [userCenter] just to animate the camera. We do *not* update [latLng] or [marker].
  Future<void> _initializeLocation() async {
    try {
      // Quick fallback: last known position (if any).
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        userCenter = LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      // Now get a fresh high-accuracy position.
      Position current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userCenter = LatLng(current.latitude, current.longitude);
      setState(() {
        // Just calling setState so that if userCenter changed, we can animate in onMapCreated.
      });
    } catch (e) {
      print("Error initializing location: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Once the map is created, if we have [userCenter], animate the camera there.
  /// We do NOT change the estate marker or latLng.
  void _onMapCreated(GoogleMapController controller) async {
    print("Google Map created.");
    _controller = controller;
    if (userCenter != null) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userCenter!,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  /// Search function using Google Geocoding API.
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      print("Search query is empty.");
      setState(() {
        _searchResults = [];
      });
      return;
    }
    print("Searching for: $query");
    try {
      final GeocodingResponse response =
          await _geocoding.searchByAddress(query);
      if (response.status == 'OK' && response.results.isNotEmpty) {
        setState(() {
          _searchResults = response.results;
        });
        // Debug log: print all result coordinates.
        for (int i = 0; i < response.results.length; i++) {
          final result = response.results[i];
          print(
              "Result ${i + 1}: (${result.geometry.location.lat}, ${result.geometry.location.lng})");
        }
      } else {
        print("No locations found for query: $query");
        if (response.errorMessage != null) {
          print("Error message: ${response.errorMessage}");
        }
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      print("Error searching location: $e");
      setState(() {
        _searchResults = [];
      });
    }
  }

  /// Called when the user picks a location from the search suggestions.
  /// This updates the estate location (latLng + marker).
  Future<void> _selectLocation(GeocodingResult result) async {
    print("Selected location: ${result.formattedAddress}");
    LatLng newLatLng =
        LatLng(result.geometry.location.lat, result.geometry.location.lng);

    setState(() {
      latLng = newLatLng;
      marker = Marker(
        markerId: const MarkerId('marker_1'),
        position: newLatLng,
        infoWindow: InfoWindow(title: result.formattedAddress),
      );
      _searchResults = []; // Clear search suggestions after selection.
      _searchController.text = result.formattedAddress!;
    });

    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16.0),
        ),
      );
      print("Moved to new location: ($newLatLng)");
    } else {
      print("GoogleMapController is not available.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // We do NOT block rendering if userCenter is null; we simply show the map
    // at the default location. Then once userCenter is available, we animate to it.
    return Scaffold(
      body: Stack(
        children: [
          // The map itself
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: latLng, // Default estate location
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (argument) {
                // If user taps the map, we update the estate location + marker.
                print(
                    "Map tapped at: (${argument.latitude}, ${argument.longitude})");
                setState(() {
                  latLng = argument;
                  marker = Marker(
                    markerId: const MarkerId('marker_1'),
                    position: argument,
                    infoWindow: const InfoWindow(),
                  );
                  _searchResults = []; // Clear suggestions on tap
                });
              },
              markers: {marker},
            ),
          ),
          // Persistent search bar at the top.
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: getTranslated(context, "Search"),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _searchLocation(_searchController.text);
                    },
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLocation,
              ),
            ),
          ),
          // Suggestions list below the search bar.
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 100,
              left: 15,
              right: 15,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 200, // Limit the height of the suggestions list.
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title:
                          Text(result.formattedAddress ?? "Unknown location"),
                      onTap: () => _selectLocation(result),
                    );
                  },
                ),
              ),
            ),
          // "Next" button at the bottom.
          Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: () async {
                print("Next button tapped. Checking location...");
                // If the latLng is still at the default, user didn't pick a location.
                if (latLng.latitude == 24.662469396093744 &&
                    latLng.longitude == 46.72888085246086) {
                  showDialog(
                    context: context,
                    builder: (context) => const FailureDialog(
                      text: "Location Not Set",
                      text1: "Please select the location of your estate",
                    ),
                  );
                  return;
                }

                // Otherwise, user has chosen a location. Update Firebase.
                try {
                  print("Updating Firebase with selected location...");
                  await ref
                      .child(widget.typeEstate)
                      .child(widget.id.toString())
                      .update({
                    "Lat": latLng.latitude,
                    "Lon": latLng.longitude,
                  });
                  print("Firebase updated successfully.");

                  if (widget.typeEstate == "Hottel") {
                    print("Navigating to AdditionalFacility screen...");
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AdditionalFacility(
                        CheckState: "add",
                        CheckIsBooking: false,
                        IDEstate: widget.id,
                        estate: const {},
                      ),
                    ));
                  } else {
                    print("Navigating to AddImage screen...");
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddImage(
                        IDEstate: widget.id.toString(),
                        typeEstate: widget.typeEstate,
                      ),
                    ));
                  }
                } catch (e) {
                  print("Error updating Firebase or navigating: $e");
                }
              },
              child: Container(
                width: 150.w,
                height: 6.h,
                margin: const EdgeInsets.only(right: 40, left: 40, bottom: 20),
                decoration: BoxDecoration(
                  color: kDeepPurpleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    getTranslated(context, "Next"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
