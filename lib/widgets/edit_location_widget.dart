// Add these imports at the top of edit_estate_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:daimond_host_provider/private.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';
import '../screens/full_map_screen.dart';

class EditLocationSection extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationChanged;

  const EditLocationSection({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
  });

  @override
  State<EditLocationSection> createState() => _EditLocationSectionState();
}

class _EditLocationSectionState extends State<EditLocationSection> {
  late LatLng _currentLocation;
  GoogleMapController? _mapController;
  Marker? _marker;

  // --- Search UI (same as map_screen) ---
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _searching = false;
  bool _showDropdown = false;
  Timer? _debounce;

  String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  final List<_PlaceSuggestion> _suggestions = [];

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
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- MAP HELPERS ----------------

  Future<void> _animateTo(LatLng target, {double zoom = 16}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _setLocation(LatLng newLoc, {String? title}) {
    setState(() {
      _currentLocation = newLoc;
      _marker = Marker(
        markerId: const MarkerId('estate_location'),
        position: newLoc,
        infoWindow: InfoWindow(title: title ?? ""),
      );
      _showDropdown = false;
      _suggestions.clear();
    });
    widget.onLocationChanged(newLoc);
  }

  void _onMapTapped(LatLng tapped) {
    _focusNode.unfocus();
    _setLocation(tapped);
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(pos.latitude, pos.longitude);
      await _animateTo(target, zoom: 16);
      // Optional: also update marker to my location
      _setLocation(target, title: getTranslated(context, "My Location"));
    } catch (_) {
      // ignore
    }
  }

  // ---------------- PLACES AUTOCOMPLETE ----------------

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchAutocomplete(v);
    });
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

    // bias around current marker
    final bias = _currentLocation;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Couldn't fetch place details. Try again.")),
      );
      return;
    }

    _setLocation(latLngFromPlace, title: s.description);
    await _animateTo(latLngFromPlace, zoom: 16);

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

  // ---------------- FULL SCREEN ----------------

  Future<void> _openFullScreenMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMap(initialLocation: _currentLocation),
      ),
    );
    if (result != null && result is LatLng) {
      _setLocation(result);
      await _animateTo(result, zoom: 16);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showDropdown = false);
        },
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
                myLocationButtonEnabled: false, // we'll use our custom button
              ),
            ),

            // Search bar (top)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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

                  // Dropdown suggestions
                  if (_showDropdown)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
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
                                          fontWeight: FontWeight.w600,
                                        ),
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

            // My Location button (right, under search)
            Positioned(
              right: 12,
              top: 62,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _goToMyLocation,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.my_location, size: 20),
                  ),
                ),
              ),
            ),

            // Full screen button (bottom right)
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _openFullScreenMap,
                child: const Icon(Icons.fullscreen, color: Colors.black87),
              ),
            ),
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
