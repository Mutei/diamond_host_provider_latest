import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../screens/seat_map_builder_screen.dart';

class AddEstateServices {
  final ImagePicker imagePicker = ImagePicker();
  final FirebaseStorage storage = FirebaseStorage.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref("App").child("Estate");
  DatabaseReference refID =
      FirebaseDatabase.instance.ref("App").child("EstateID");

  Future<List<XFile>?> openImages() async {
    try {
      var pickedFiles = await imagePicker.pickMultiImage();
      return pickedFiles;
    } catch (e) {
      print("Error while picking file: $e");
      return null;
    }
  }

  /// Writes full layout info:
  /// - size
  /// - includeOutdoor + outdoorSides
  /// - includeSecondFloor + secondFloorSides
  /// - spots_indoor, spots_outdoor, spots_second
  /// Also sets estate.LayoutId
  Future<void> uploadAutoCadLayout({
    required String childType,
    required String estateId,
    required AutoCadLayout layout,
  }) async {
    final layoutRef = FirebaseDatabase.instance
        .ref("App/Estate/$childType/$estateId/AutoCad/${layout.layoutId}");

    await layoutRef.update({
      'includeOutdoor': layout.includeOutdoor,
      'outdoorSides': layout.outdoorSides.map((s) => s.name).toList(),
      'includeSecondFloor': layout.includeSecondFloor,
      'secondFloorSides': layout.secondFloorSides.map((s) => s.name).toList(),
      'size': {
        'width': layout.width,
        'height': layout.height,
        'timestamp': ServerValue.timestamp,
      },
    });

    // Indoor
    final indoorRef = layoutRef.child('spots_indoor');
    await indoorRef.remove();
    for (final spot in layout.spotsIndoor) {
      await indoorRef.child(spot.id).set({
        'type': spot.type.name,
        'shape': spot.shape.name,
        'capacity': spot.capacity,
        'seatType': spot.seatType.name,
        'decorationType': spot.decorationType?.name,
        'x': spot.x,
        'y': spot.y,
        'w': spot.w,
        'h': spot.h,
        'rotation': spot.rotation,
        'color': spot.color.value,
        'timestamp': ServerValue.timestamp,
      });
    }

    // Outdoor
    final outdoorRef = layoutRef.child('spots_outdoor');
    await outdoorRef.remove();
    for (final spot in layout.spotsOutdoor) {
      await outdoorRef.child(spot.id).set({
        'type': spot.type.name,
        'shape': spot.shape.name,
        'capacity': spot.capacity,
        'seatType': spot.seatType.name,
        'decorationType': spot.decorationType?.name,
        'x': spot.x,
        'y': spot.y,
        'w': spot.w,
        'h': spot.h,
        'rotation': spot.rotation,
        'color': spot.color.value,
        'timestamp': ServerValue.timestamp,
      });
    }

    // Second floor
    final secondRef = layoutRef.child('spots_second');
    await secondRef.remove();
    for (final spot in layout.spotsSecond) {
      await secondRef.child(spot.id).set({
        'type': spot.type.name,
        'shape': spot.shape.name,
        'capacity': spot.capacity,
        'seatType': spot.seatType.name,
        'decorationType': spot.decorationType?.name,
        'x': spot.x,
        'y': spot.y,
        'w': spot.w,
        'h': spot.h,
        'rotation': spot.rotation,
        'color': spot.color.value,
        'timestamp': ServerValue.timestamp,
      });
    }

    // Point estate to this layout
    await FirebaseDatabase.instance
        .ref("App/Estate/$childType/$estateId")
        .update({'LayoutId': layout.layoutId});
  }

  // Modified Method: Now accepts String path instead of XFile
  Future<String?> uploadFacilityPdfToStorage(
      String pdfPath, String idEstate) async {
    try {
      Reference storageRef =
          storage.ref().child("estates/$idEstate/facility_document.pdf");
      UploadTask uploadTask = storageRef.putFile(File(pdfPath));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading PDF: $e");
      return null;
    }
  }

  Future<String?> uploadTaxPdfToStorage(String pdfPath, String idEstate) async {
    try {
      Reference storageRef =
          storage.ref().child("estates/$idEstate/tax_document.pdf");
      UploadTask uploadTask = storageRef.putFile(File(pdfPath));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading PDF: $e");
      return null;
    }
  }

  // Method to open a single PDF picker
  Future<FilePickerResult?> openSinglePdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      return result;
    } catch (e) {
      print("Error while picking PDF: $e");
      return null;
    }
  }

  Future<String?> getTypeAccount(String userId) async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("App")
        .child("Users")
        .child(userId)
        .child("TypeAccount");
    DataSnapshot snapshot = await ref.get();
    return snapshot.value as String?;
  }

  Future<int?> getIdEstate() async {
    DatabaseReference starCountRef =
        FirebaseDatabase.instance.ref("App").child("EstateID");
    DataSnapshot snapshot = await starCountRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return data['EstateID'] ?? 1;
    }
    return null;
  }

  Future<void> addEstate({
    required String childType,
    required String idEstate,
    required String nameAr,
    required String nameEn,
    required String bioAr,
    required String bioEn,
    required String country,
    required String branchEn,
    required String branchAr,
    required String city,
    required String state,
    required String userType,
    required String userID,
    required String typeAccount,
    required String taxNumber,
    required String music,
    required List<String> listTypeOfRestaurant,
    required List<String> listSessions,
    required List<String> roomAllowance,
    required List<String> additionals,
    required List<String> listMusic,
    required List<String> listEntry,
    required String price,
    required String priceLast,
    required String ownerFirstName,
    required String ownerLastName,
    required String menuLink,
    required bool hasValet,
    required bool valetWithFees,
    required bool hasKidsArea,
    required bool hasSwimmingPool,
    required bool hasBarber,
    required bool hasMassage,
    required bool hasGym,
    required bool isSmokingAllowed,
    required bool isThereDinnerLounge,
    required String breakfastLoungePrice,
    required String launchLoungePrice,
    required String dinnerLoungePrice,
    required bool isThereBreakfastLounge,
    required bool isThereLaunchLounge,
    String? facilityImageUrl,
    String? taxImageUrl,
    String? layoutId,
    required bool hasJacuzzi,
    required String estatePhoneNumber,

    // ===== NEW (Photographer) =====
    String? dateOfPhotography,
    String? dayOfPhotography,
    String? timeOfPhotography,

    // ===== NEW (Metro) =====
    // required String metroCity, // "Riyadh" or empty
    // required List<String> metroLines, // selected line color names
    // required Map<String, List<String>> metroStationsByLine, // line -> stations
  }) async {
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Metro payload
    // Map<String, dynamic>? metroNode;
    // if (metroCity.trim().toLowerCase() == 'riyadh' && metroLines.isNotEmpty) {
    //   final Map<String, dynamic> linesNode = {};
    //   for (final line in metroLines) {
    //     final stations = metroStationsByLine[line] ?? const <String>[];
    //     linesNode[line] = {
    //       'Stations': stations.join(','), // stored as comma-separated EN names
    //     };
    //   }
    //   metroNode = {
    //     'City': 'Riyadh',
    //     'Lines': linesNode,
    //   };
    // }

    final Map<String, dynamic> base = {
      "NameAr": nameAr,
      "NameEn": nameEn,
      "Owner of Estate Name": "$ownerFirstName $ownerLastName",
      "BioAr": bioAr,
      "BioEn": bioEn,
      "BranchEn": branchEn,
      "BranchAr": branchAr,
      "Country": country,
      "EstatePhoneNumber": estatePhoneNumber,
      "BreakfastLoungePrice": breakfastLoungePrice,
      "LaunchLoungePrice": launchLoungePrice,
      "DinnerLoungePrice": dinnerLoungePrice,
      "City": city,
      "State": state,
      "Type": userType,
      "IDUser": userID,
      "IDEstate": idEstate,
      "TypeAccount": typeAccount,
      "DateOfRegisteredEstate": registrationDate,
      "Music": music,
      if (userType == "3") "TypeofRestaurant": listTypeOfRestaurant.join(","),
      if (userType == "2" || userType == "3")
        "Sessions": listSessions.join(","),
      if (userType == "2") "Lstmusic": listMusic.join(","),
      "Entry": listEntry.join(","),
      if (userType == "1") "Price": price,
      if (userType == "1") "PriceLast": priceLast,
      "MenuLink": menuLink,
      "additionals": additionals.join(","),
      "roomServices": roomAllowance.join(","),
      "HasValet": hasValet ? "1" : "0",
      "ValetWithFees": valetWithFees ? "1" : "0",
      "HasKidsArea": hasKidsArea ? "1" : "0",
      if (userType == "1") "HasSwimmingPool": hasSwimmingPool ? "1" : "0",
      if (userType == "1") "HasJacuzziInRoom": hasJacuzzi ? "1" : "0",
      if (userType == "1") "HasBarber": hasBarber ? "1" : "0",
      if (userType == "1") "HasMassage": hasMassage ? "1" : "0",
      if (userType == "1") "HasGym": hasGym ? "1" : "0",
      "IsSmokingAllowed": isSmokingAllowed ? "1" : "0",
      "IsThereBreakfastLounge": isThereBreakfastLounge ? "1" : "0",
      "IsThereLaunchLounge": isThereLaunchLounge ? "1" : "0",
      "IsThereDinnerLounge": isThereDinnerLounge ? "1" : "0",
      "FacilityPdfUrl": facilityImageUrl ?? "",
      "TaxPdfUrl": taxImageUrl ?? "",
      "IsAccepted": "1",
      "IsCompleted": "0",
      if (layoutId != null) "LayoutId": layoutId,
    };

    // NEW (Photographer) — nested node if any of the three fields is provided
    if ((dateOfPhotography != null && dateOfPhotography.isNotEmpty) ||
        (dayOfPhotography != null && dayOfPhotography.isNotEmpty) ||
        (timeOfPhotography != null && timeOfPhotography.isNotEmpty)) {
      base["Photography"] = {
        if (dateOfPhotography != null && dateOfPhotography.isNotEmpty)
          "DateOfPhotography": dateOfPhotography, // e.g., 2025-08-31
        if (dayOfPhotography != null && dayOfPhotography.isNotEmpty)
          "DayOfPhotography": dayOfPhotography, // e.g., Sunday
        if (timeOfPhotography != null && timeOfPhotography.isNotEmpty)
          "TimeOfPhotography": timeOfPhotography, // e.g., 17:00
      };
    }

    // if (metroNode != null) {
    //   base["Metro"] = metroNode;
    // }

    await ref.child(childType).child(idEstate).set(base);
  }

  Future<void> rejectEstate(String childType, String estateId) async {
    await ref.child(childType).child(estateId).remove();
  }

  Future<void> approveEstate(String childType, String estateId) async {
    await ref.child(childType).child(estateId).update({"IsAccepted": "2"});
  }

  // Method to open a single image picker
  Future<XFile?> openSingleImage() async {
    try {
      XFile? pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);
      return pickedFile;
    } catch (e) {
      print("Error while picking image: $e");
      return null;
    }
  }

  Future<void> addRoom({
    required String estateId,
    required String roomId,
    required String roomName,
    required String roomPrice,
    required String roomBioAr,
    required String roomBioEn,
  }) async {
    DatabaseReference refHotelRooms = FirebaseDatabase.instance
        .ref("App")
        .child("Estate")
        .child("Hottel")
        .child(estateId)
        .child("Rooms")
        .child(roomName);

    await refHotelRooms.set({
      "ID": roomId,
      "Name": roomName,
      "Price": roomPrice,
      "BioAr": roomBioAr,
      "BioEn": roomBioEn,
    });
  }

  Future<void> updateEstateId(int newIdEstate) async {
    await refID.update({"EstateID": newIdEstate});
  }

  Future<Map<String, String?>> getUserDetails(String userId) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("App").child("User").child(userId);
    DataSnapshot firstNameSnapShot = await userRef.child("FirstName").get();
    DataSnapshot lastNameSnapShot = await userRef.child("LastName").get();
    DataSnapshot typeAccountSnapShot = await userRef.child("TypeAccount").get();

    return {
      "firstName": firstNameSnapShot.value as String?,
      "lastName": lastNameSnapShot.value as String?,
      "typeAccount": typeAccountSnapShot.value as String?,
    };
  }

  Future<void> markEstateAsCompleted(String type, String idEstate) async {
    await ref.child(type).child(idEstate).update({"IsCompleted": "1"});
  }
}
