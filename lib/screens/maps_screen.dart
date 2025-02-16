import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../localization/language_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'add_image_screen.dart';
import 'additional_facility_screen.dart';

class MapsScreen extends StatefulWidget {
  final String id;
  final String typeEstate;

  MapsScreen({super.key, required this.id, required this.typeEstate});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  LatLng latLng = const LatLng(37.7749, -122.4194);
  DatabaseReference ref = FirebaseDatabase.instance.ref("App").child("Estate");
  GoogleMapController? _controller;
  LatLng _center = const LatLng(37.7749, -122.4194);

  void _onMapCreated(GoogleMapController controller) async {
    print("Google Map created.");
    _controller = controller;
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    print("Getting current location...");
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Current location: (${position.latitude}, ${position.longitude})");
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _center,
              zoom: 16.0,
            ),
          ),
        );
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Marker marker = const Marker(
    markerId: MarkerId('marker_1'),
    position: LatLng(37.7749, -122.4194),
    infoWindow: InfoWindow(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(_center.latitude, _center.longitude),
                  zoom: 11.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: (argument) {
                  print(
                      "Map tapped at: (${argument.latitude}, ${argument.longitude})");
                  latLng = argument;
                  setState(() {
                    marker = Marker(
                      markerId: const MarkerId('marker_1'),
                      position: LatLng(latLng.latitude, latLng.longitude),
                      infoWindow: InfoWindow(),
                    );
                  });
                },
                markers: Set<Marker>.of([marker]),
              )),
          Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: () async {
                print("Next button tapped. Updating Firebase...");
                try {
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
                    Map e = Map();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AdditionalFacility(
                              CheckState: "add",
                              CheckIsBooking: false,
                              IDEstate: widget.id,
                              estate: e,
                            )));
                  } else {
                    print("Navigating to AddImage screen...");
                    Map e = Map();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddImage(
                              IDEstate: widget.id.toString(),
                              typeEstate: widget.typeEstate, // Pass typeEstate
                            )));
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
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
