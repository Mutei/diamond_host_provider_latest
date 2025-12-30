import 'package:daimond_host_provider/private.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/failure_dialogue.dart';
import 'add_image_screen.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../widgets/riyadh_metro_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

// UI state
  bool _searching = false;
  bool _showDropdown = false;

// debounce
  Timer? _debounce;

// session token
  String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

// suggestions list (Places Autocomplete)
  final List<_PlaceSuggestion> _suggestions = [];

  final MetroSelectionController _metroCtrl = MetroSelectionController();

  String _resolvedCity = "";
  String _resolvedState = "";
  String _resolvedCountry = "";
  bool _isSubmitting = false;

  bool _hasPartialMetroSelection() {
    final lines = _metroCtrl.chosenLines;
    for (final ln in lines) {
      final st = _metroCtrl.chosenStationsByLine[ln];
      if (st == null || st.isEmpty) return true;
    }
    return false;
  }

  Future<void> _animateToUser() async {
    if (_controller == null || userCenter == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userCenter!, zoom: 16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _refreshResolvedPlace(LatLng p) async {
    final ccs = await _reverseGeocodeWithGeocodingPkg(p);
    setState(() {
      _resolvedCountry = (ccs["Country"] ?? "").trim();
      _resolvedState = (ccs["State"] ?? "").trim();
      _resolvedCity = (ccs["City"] ?? "").trim();
    });
  }

  Future<Map<String, String>> _reverseGeocodeWithGeocodingPkg(LatLng p) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
        // localeIdentifier: "en",
      );

      if (placemarks.isEmpty) return {};

      final pm = placemarks.first;

      // city: locality is usually the city
      final city = (pm.locality ?? pm.subAdministrativeArea ?? "").trim();

      // state: administrativeArea is the region/province
      final state = (pm.administrativeArea ?? "").trim();

      // country
      final country = (pm.country ?? "").trim();

      final out = <String, String>{};
      if (country.isNotEmpty) out["Country"] = country;
      if (state.isNotEmpty) out["State"] = state;
      if (city.isNotEmpty) out["City"] = city;

      print("✅ Reverse result => $out");
      return out;
    } catch (e) {
      print("❌ Reverse geocode error: $e");
      return {};
    }
  }

  String _composeBranchFromPlacemark(geo.Placemark pm) {
    // Build a clean “branch” name from available parts
    // Example output: "Al Olaya, Riyadh" or "Al Wurud, Riyadh"
    final parts = <String>[
      (pm.subLocality ?? "").trim(),
      (pm.locality ?? pm.subAdministrativeArea ?? "").trim(),
    ].where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) {
      // fallback
      final street = (pm.street ?? "").trim();
      return street.isNotEmpty ? street : "";
    }
    return parts.join(", ");
  }

  Future<Map<String, String>> _getBranchEnAr(LatLng p) async {
    try {
      // EN placemark
      final enPlacemarks = await geo.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );

      // AR placemark
      final arPlacemarks = await geo.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );

      final enPm = enPlacemarks.isNotEmpty ? enPlacemarks.first : null;
      final arPm = arPlacemarks.isNotEmpty ? arPlacemarks.first : null;

      final branchEn = enPm == null ? "" : _composeBranchFromPlacemark(enPm);
      final branchAr = arPm == null ? "" : _composeBranchFromPlacemark(arPm);

      // If Arabic came back empty, fallback to EN
      return {
        "BranchEn": branchEn,
        "BranchAr": branchAr.isNotEmpty ? branchAr : branchEn,
      };
    } catch (e) {
      print("❌ Branch reverse geocode error: $e");
      return {"BranchEn": "", "BranchAr": ""};
    }
  }

  /// Fetch the user's location (quick fallback with last known, then high-accuracy).
  /// Store it in [userCenter] just to animate the camera. We do *not* update [latLng] or [marker].
  Future<void> _initializeLocation() async {
    try {
      // Ensure permissions
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        print("❌ Location permission denied");
        return;
      }

      // Quick fallback: last known
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        userCenter = LatLng(lastKnown.latitude, lastKnown.longitude);
        await _animateToUser(); // ✅ animate if map is ready
      }

      // Fresh high accuracy
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userCenter = LatLng(current.latitude, current.longitude);

      setState(() {}); // update state
      await _animateToUser(); // ✅ animate again with accurate position
    } catch (e) {
      print("Error initializing location: $e");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Once the map is created, if we have [userCenter], animate the camera there.
  /// We do NOT change the estate marker or latLng.
  void _onMapCreated(GoogleMapController controller) async {
    print("Google Map created.");
    _controller = controller;
    await _animateToUser();
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

  Future<void> _fetchAutocomplete(String input) async {
    final q = input.trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions.clear();
        _showDropdown = false;
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _showDropdown = true;
    });

    // bias near user's location if available, otherwise Riyadh
    final bias = userCenter ?? const LatLng(24.7136, 46.6753);

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
      "?input=${Uri.encodeComponent(q)}"
      "&key=${PrivateKeys.googleMapsApiKey}"
      "&language=en"
      "&components=country:sa"
      "&location=${bias.latitude},${bias.longitude}"
      "&radius=50000"
      "&sessiontoken=$_sessionToken",
    );

    try {
      final res = await http.get(url);
      final data = json.decode(res.body);

      if (data["status"] != "OK" && data["status"] != "ZERO_RESULTS") {
        setState(() {
          _suggestions.clear();
          _searching = false;
          _showDropdown = false;
        });
        return;
      }

      final preds = (data["predictions"] as List<dynamic>? ?? [])
          .map(
            (e) => _PlaceSuggestion(
              placeId: (e["place_id"] ?? "").toString(),
              description: (e["description"] ?? "").toString(),
            ),
          )
          .where((e) => e.placeId.isNotEmpty)
          .toList();

      setState(() {
        _suggestions
          ..clear()
          ..addAll(preds);
        _searching = false;
        _showDropdown = preds.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _suggestions.clear();
        _searching = false;
        _showDropdown = false;
      });
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      // permissions
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      // use current position (best), fallback to stored userCenter
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(pos.latitude, pos.longitude);
      userCenter = target;

      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
    } catch (e) {
      // fallback if GPS fails
      if (userCenter != null) {
        await _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: userCenter!, zoom: 16),
          ),
        );
      }
    }
  }

  Future<LatLng?> _fetchLatLngFromPlaceId(String placeId) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=$placeId"
      "&fields=geometry"
      "&key=${PrivateKeys.googleMapsApiKey}"
      "&sessiontoken=$_sessionToken",
    );

    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data["status"] != "OK") return null;

    final loc = data["result"]["geometry"]["location"];
    return LatLng(
      (loc["lat"] as num).toDouble(),
      (loc["lng"] as num).toDouble(),
    );
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchAutocomplete(v);
    });
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _focusNode.unfocus();

    setState(() {
      _searchController.text = s.description;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
      _showDropdown = false;
    });

    final latLngFromPlace = await _fetchLatLngFromPlaceId(s.placeId);
    if (latLngFromPlace == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't fetch place details. Try again.")),
        );
      }
      return;
    }

    await _refreshResolvedPlace(latLngFromPlace);

    setState(() {
      latLng = latLngFromPlace;
      marker = Marker(
        markerId: const MarkerId('marker_1'),
        position: latLngFromPlace,
        infoWindow: InfoWindow(title: s.description),
      );
      _suggestions.clear();
    });

    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLngFromPlace, zoom: 16),
      ),
    );

    // refresh session token after success
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _clearSearch() {
    _searchController.clear();
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _suggestions.clear();
      _showDropdown = false;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We do NOT block rendering if userCenter is null; we simply show the map
    // at the default location. Then once userCenter is available, we animate to it.
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showDropdown = false);
        },
        child: Stack(
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
                myLocationButtonEnabled: false,
                onTap: (argument) {
                  setState(() {
                    latLng = argument;
                    marker = Marker(
                      markerId: const MarkerId('marker_1'),
                      position: argument,
                      infoWindow: const InfoWindow(),
                    );
                    _suggestions.clear();
                    _showDropdown = false;
                  });
                  _refreshResolvedPlace(argument);
                },
                markers: {marker},
              ),
            ),
            // Persistent search bar at the top.
            Positioned(
              left: 15,
              right: 15,
              top: MediaQuery.of(context).padding.top + 10,
              child: Column(
                children: [
                  Material(
                    elevation: 10,
                    shadowColor: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _onSearchChanged,
                              onTap: () {
                                if (_suggestions.isNotEmpty) {
                                  setState(() => _showDropdown = true);
                                }
                              },
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: getTranslated(context, "Search"),
                              ),
                            ),
                          ),
                          if (_searching)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                              splashRadius: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDropdown)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (_, i) {
                            final s = _suggestions[i];
                            return InkWell(
                              onTap: () => _selectSuggestion(s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        s.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 15,
              top: MediaQuery.of(context).padding.top + 10 + 62, // under search
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _goToMyLocation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, size: 20),
                        SizedBox(width: 8),
                        Text(
                          getTranslated(context, "My Location"),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Suggestions list below the search bar.

            // "Next" button at the bottom.
            // ✅ Show Metro picker ONLY if city is Riyadh
            if (_resolvedCity.toLowerCase().trim() == "riyadh")
              Positioned(
                left: 15,
                right: 15,
                bottom: 95, // above the Next button
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: RiyadhMetroPicker(
                    controller: _metroCtrl,
                    isVisible: true,
                  ),
                ),
              ),

            Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: _isSubmitting
                    ? null
                    : () async {
                        if (latLng.latitude == 24.662469396093744 &&
                            latLng.longitude == 46.72888085246086) {
                          showDialog(
                            context: context,
                            builder: (context) => const FailureDialog(
                              text: "Location Not Set",
                              text1:
                                  "Please select the location of your estate",
                            ),
                          );
                          return;
                        }

                        setState(() => _isSubmitting = true);

                        try {
                          final estateRef = FirebaseDatabase.instance
                              .ref("App")
                              .child("Estate")
                              .child(widget.typeEstate)
                              .child(widget.id.toString());

                          // 1) Lat/Lon
                          await estateRef.update({
                            "Lat": latLng.latitude,
                            "Lon": latLng.longitude,
                          });

                          // 2) Country/City/State
                          final ccs =
                              await _reverseGeocodeWithGeocodingPkg(latLng);
                          if (ccs.isNotEmpty) {
                            await estateRef.update(ccs);
                          }

                          // 2.1) BranchEn / BranchAr
                          final branches = await _getBranchEnAr(latLng);
                          if ((branches["BranchEn"] ?? "").isNotEmpty ||
                              (branches["BranchAr"] ?? "").isNotEmpty) {
                            await estateRef.update({
                              "BranchEn": branches["BranchEn"] ?? "",
                              "BranchAr": branches["BranchAr"] ?? "",
                            });
                          }

                          // 3) Metro
                          final city =
                              (ccs["City"] ?? _resolvedCity).toString().trim();
                          final isRiyadh = city.toLowerCase() == "riyadh";

                          if (!isRiyadh) {
                            await estateRef.child("Metro").remove();
                          } else {
                            if (_metroCtrl.chosenLines.isNotEmpty) {
                              final Map<String, dynamic> linesNode = {};
                              for (final line in _metroCtrl.chosenLines) {
                                final stations =
                                    _metroCtrl.chosenStationsByLine[line] ??
                                        const <String>[];
                                linesNode[line] = {
                                  "Stations": stations.join(",")
                                };
                              }
                              await estateRef.child("Metro").set({
                                "City": "Riyadh",
                                "Lines": linesNode,
                              });
                            } else {
                              await estateRef.child("Metro").remove();
                            }
                          }

                          if (!mounted) return;

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => AddImage(
                                IDEstate: widget.id.toString(),
                                typeEstate: widget.typeEstate,
                              ),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Failed. Please try again.")),
                            );
                            setState(() => _isSubmitting = false);
                          }
                        }
                      },
                child: Container(
                  width: 150.w,
                  height: 6.h,
                  margin:
                      const EdgeInsets.only(right: 40, left: 40, bottom: 20),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? Colors.grey : kDeepPurpleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            getTranslated(context, "Next"),
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),

            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: InkWell(
            //     onTap: () async {
            //       print("Next button tapped. Checking location...");
            //
            //       // If the latLng is still at the default, user didn't pick a location.
            //       if (latLng.latitude == 24.662469396093744 &&
            //           latLng.longitude == 46.72888085246086) {
            //         showDialog(
            //           context: context,
            //           builder: (context) => const FailureDialog(
            //             text: "Location Not Set",
            //             text1: "Please select the location of your estate",
            //           ),
            //         );
            //         return;
            //       }
            //
            //       try {
            //         print("Updating Firebase with selected location...");
            //
            //         final estateRef = FirebaseDatabase.instance
            //             .ref("App")
            //             .child("Estate")
            //             .child(widget.typeEstate)
            //             .child(widget.id.toString());
            //
            //         print(
            //             "✅ Updating node: App/Estate/${widget.typeEstate}/${widget.id}");
            //
            //         // ✅ 1) Save Lat/Lon first
            //         await estateRef.update({
            //           "Lat": latLng.latitude,
            //           "Lon": latLng.longitude,
            //         });
            //
            //         // ✅ 2) Reverse geocode => Country/City/State
            //         final ccs = await _reverseGeocodeWithGeocodingPkg(latLng);
            //
            //         if (ccs.isNotEmpty) {
            //           await estateRef.update(ccs);
            //           print("✅ Country/City/State updated in DB");
            //         } else {
            //           print(
            //               "⚠️ Reverse returned empty. Country/City/State not updated.");
            //         }
            //
            //         // ✅ 2.1) Build & save BranchEn / BranchAr from location (like edit screen)
            //         final branches = await _getBranchEnAr(latLng);
            //         if ((branches["BranchEn"] ?? "").isNotEmpty ||
            //             (branches["BranchAr"] ?? "").isNotEmpty) {
            //           await estateRef.update({
            //             "BranchEn": branches["BranchEn"] ?? "",
            //             "BranchAr": branches["BranchAr"] ?? "",
            //           });
            //           print("✅ BranchEn/BranchAr updated in DB");
            //         } else {
            //           print("⚠️ BranchEn/BranchAr empty from reverse geocode");
            //         }
            //
            //         // ✅ 3) Metro logic (ONLY if City == Riyadh)
            //         final city = (ccs["City"] ?? _resolvedCity).toString().trim();
            //         final isRiyadh = city.toLowerCase() == "riyadh";
            //
            //         if (!isRiyadh) {
            //           // Not Riyadh => remove any Metro info (keep DB clean)
            //           await estateRef.child("Metro").remove();
            //           print("🧹 Metro removed (city is not Riyadh)");
            //         } else {
            //           // Riyadh => save Metro only if user selected something
            //           if (_metroCtrl.chosenLines.isNotEmpty) {
            //             final Map<String, dynamic> linesNode = {};
            //
            //             for (final line in _metroCtrl.chosenLines) {
            //               final stations =
            //                   _metroCtrl.chosenStationsByLine[line] ??
            //                       const <String>[];
            //
            //               linesNode[line] = {
            //                 "Stations": stations
            //                     .join(","), // comma-separated station EN names
            //               };
            //             }
            //
            //             await estateRef.child("Metro").set({
            //               "City": "Riyadh",
            //               "Lines": linesNode,
            //             });
            //
            //             print("✅ Metro saved under App/Estate/.../Metro");
            //           } else {
            //             // Riyadh but no selection => remove Metro
            //             await estateRef.child("Metro").remove();
            //             print("🧹 Metro removed (Riyadh but no lines selected)");
            //           }
            //         }
            //
            //         print("Firebase updated successfully.");
            //         final snap = await estateRef.get();
            //         print("📌 DB after updates => ${snap.value}");
            //
            //         // ✅ Navigate to AddImage
            //         Navigator.of(context).pushAndRemoveUntil(
            //           MaterialPageRoute(
            //             builder: (context) => AddImage(
            //               IDEstate: widget.id.toString(),
            //               typeEstate: widget.typeEstate,
            //             ),
            //           ),
            //           (Route<dynamic> route) => false,
            //         );
            //       } catch (e) {
            //         print("Error updating Firebase or navigating: $e");
            //       }
            //     },
            //     child: Container(
            //       width: 150.w,
            //       height: 6.h,
            //       margin: const EdgeInsets.only(right: 40, left: 40, bottom: 20),
            //       decoration: BoxDecoration(
            //         color: kDeepPurpleColor,
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Center(
            //         child: Text(
            //           getTranslated(context, "Next"),
            //           style: const TextStyle(color: Colors.white),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;
  _PlaceSuggestion({required this.placeId, required this.description});
}
