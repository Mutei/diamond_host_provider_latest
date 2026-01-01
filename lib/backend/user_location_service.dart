// lib/backend/user_location_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

class UserLocationService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Saves City/Country + Location ONLY ONCE.
  /// If Location already exists in DB, it will NEVER update again,
  /// even if the user opens the app in another city/country.
  static Future<void> saveUserCityCountryOnce() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final permOk = await _ensurePermission();
    if (!permOk) return;

    final userRef = _db.ref('App/User/$uid');

    // ✅ If Location already exists -> do nothing forever
    final locationSnap = await userRef.child('Location').get();
    if (locationSnap.exists) return;

    // Get current position
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Reverse geocode to City/Country
    final places =
        await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (places.isEmpty) return;

    final p = places.first;

    // City can be locality/subAdministrativeArea depending on region
    final city = (p.locality?.trim().isNotEmpty == true)
        ? p.locality!.trim()
        : (p.subAdministrativeArea?.trim().isNotEmpty == true)
            ? p.subAdministrativeArea!.trim()
            : (p.administrativeArea?.trim().isNotEmpty == true)
                ? p.administrativeArea!.trim()
                : '';

    final country = (p.country ?? '').trim();

    // ✅ Save once (atomic update)
    final updates = <String, dynamic>{
      'Location': {
        'Lat': pos.latitude,
        'Lng': pos.longitude,
        'UpdatedAt': ServerValue.timestamp,
      },
      if (city.isNotEmpty) 'City': city,
      if (country.isNotEmpty) 'Country': country,
    };

    await userRef.update(updates);
  }

  static Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) return false;
    if (perm == LocationPermission.deniedForever) return false;

    return true;
  }
}
