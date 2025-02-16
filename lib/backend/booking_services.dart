import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';
import 'firebase_services.dart';

class BookingServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseServices _firebaseServices = FirebaseServices();

  // Function to generate a unique ID for the booking
  String generateUniqueID() {
    var random = Random();
    return (random.nextInt(90000) + 10000)
        .toString(); // Generates a 5-digit number
  }

  // Function to fetch user rating
  Future<double?> fetchUserRating(String userId) async {
    DatabaseReference ratingRef = _dbRef
        .child("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");
    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.parse(snapshot.value.toString());
    }
    return null; // Return null if no ratings found
  }

  // Function to fetch the estate owner's ID based on estate type stored in the database as a Type field (1, 2, 3)
  Future<String?> fetchOwnerId(String estateId) async {
    try {
      // Try fetching the type from all possible estate categories (Hottel, Coffee, Restaurant)
      List<String> estateCategories = ['Hottel', 'Coffee', 'Restaurant'];
      String? estateTypePath;

      for (String category in estateCategories) {
        DatabaseReference estateTypeRef = _dbRef
            .child("App")
            .child("Estate")
            .child(category)
            .child(estateId)
            .child("Type");

        DataSnapshot typeSnapshot = await estateTypeRef.get();

        if (typeSnapshot.exists) {
          // If the type is found, determine the correct estateTypePath
          int estateType = int.parse(typeSnapshot.value.toString());
          switch (estateType) {
            case 1:
              estateTypePath = 'Hottel';
              break;
            case 2:
              estateTypePath = 'Coffee';
              break;
            case 3:
              estateTypePath = 'Restaurant';
              break;
            default:
              print("Error: Unrecognized estate type.");
              return null;
          }
          break;
        }
      }

      if (estateTypePath == null) {
        print("Error: Estate Type not found.");
        return null;
      }

      // Now that we have the correct estateTypePath, fetch the owner ID
      DatabaseReference estateRef = _dbRef
          .child("App")
          .child("Estate")
          .child(estateTypePath)
          .child(estateId)
          .child("IDUser");

      DataSnapshot estateSnapshot = await estateRef.get();
      if (estateSnapshot.exists) {
        return estateSnapshot.value?.toString(); // Return the owner ID
      } else {
        print("Error: Owner ID not found.");
        return null;
      }
    } catch (e) {
      print("Error in fetchOwnerId: $e");
      return null;
    }
  }

  // Function to create a booking
  Future<void> createBooking({
    required String estateId,
    required String nameEn,
    required String nameAr,
    required String typeOfRestaurant,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required BuildContext context,
  }) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      // Handle user not logged in
      return;
    }

    // Generate a unique booking ID
    String uniqueID = generateUniqueID();
    String bookingID = uniqueID;

    // Fetch user information
    DatabaseReference userRef = _dbRef.child("App").child("User").child(userId);
    DataSnapshot snapshot = await userRef.get();
    String firstName = snapshot.child("FirstName").value?.toString() ?? "";
    String secondName = snapshot.child("SecondName").value?.toString() ?? "";
    String lastName = snapshot.child("LastName").value?.toString() ?? "";
    String smokerStatus = snapshot.child("IsSmoker").value?.toString() ?? "No";
    String allergies = snapshot.child("Allergies").value?.toString() ?? "";
    String city = snapshot.child("City").value?.toString() ?? "";
    String country = snapshot.child("Country").value?.toString() ?? "";
    String fullName = "$firstName $secondName $lastName";

    // Fetch the estate owner ID
    String? ownerId = await fetchOwnerId(estateId);
    if (ownerId == null) {
      // Handle error if owner ID cannot be fetched
      return;
    }

    // Format the selected date (only the date, no time)
    String bookingDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Fetch user rating
    double? userRating = await fetchUserRating(userId);
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String hour = selectedTime.hour.toString().padLeft(2, '0');
    String minute = selectedTime.minute.toString().padLeft(2, '0');

    // Create booking in Firebase
    DatabaseReference bookingRef =
        _dbRef.child("App").child("Booking").child("Book");
    await bookingRef.child(bookingID).set({
      "IDEstate": estateId,
      "IDBook": bookingID,
      "NameEn": nameEn,
      "NameAr": nameAr,
      "Status": "1",
      "IDUser": userId,
      "IDOwner": ownerId,
      "StartDate": bookingDate,
      "EndDate": "",
      "Type": typeOfRestaurant,
      "Country": country,
      "State": "State",
      "City": city,
      "NameUser": fullName,
      "Smoker": smokerStatus,
      "Allergies": allergies,
      "Rating": userRating ?? 0.0,
      "DateOfBooking": registrationDate,
      "Clock": "$hour:$minute",
    });
    String providerId = ownerId;
    DatabaseReference providerTokenRef =
        FirebaseDatabase.instance.ref("App/User/$providerId/Token");
    DataSnapshot tokenSnapshot = await providerTokenRef.get();
    String? providerToken = tokenSnapshot.value?.toString();

    // Send notification to the provider
    if (providerToken != null && providerToken.isNotEmpty) {
      await _firebaseServices.sendNotificationToProvider(
        providerToken,
        getTranslated(context, "New Booking Request"),
        getTranslated(context, "You have a new booking request"),
      );
    }
    // Optionally send notification to provider using FCM (if implemented)
  }
}
