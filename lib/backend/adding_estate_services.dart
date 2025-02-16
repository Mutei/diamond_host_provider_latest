import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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

  // Modified Method: Now accepts String path instead of XFile
  Future<String?> uploadFacilityPdfToStorage(
      String pdfPath, String idEstate) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      Reference storageRef =
          storage.ref().child("estates/$idEstate/facility_document.pdf");

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(File(pdfPath));

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Error uploading PDF: $e");
      return null;
    }
  }

  Future<String?> uploadTaxPdfToStorage(String pdfPath, String idEstate) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      Reference storageRef =
          storage.ref().child("estates/$idEstate/tax_document.pdf");

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(File(pdfPath));

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
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
        allowedExtensions: ['pdf'], // Limit to PDFs
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
    String? taxImageUrl, // Consider renaming to facilityPdfUrl
    required bool hasJacuzzi,
  }) async {
    await ref.child(childType).child(idEstate).set({
      "NameAr": nameAr,
      "NameEn": nameEn,
      "Owner of Estate Name": "$ownerFirstName $ownerLastName",
      "BioAr": bioAr,
      "BioEn": bioEn,
      "Country": country,
      "BreakfastLoungePrice": breakfastLoungePrice,
      "LaunchLoungePrice": launchLoungePrice,
      "DinnerLoungePrice": dinnerLoungePrice,
      "City": city,
      "State": state,
      "Type": userType,
      "IDUser": userID,
      "IDEstate": idEstate,
      "TypeAccount": typeAccount,
      // "TaxNumber": taxNumber, // Corrected typo from "TaxNumer"
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
      "TaxPdfUrl": taxImageUrl ?? "", // Renamed for clarity
      "IsAccepted": "1",
      "IsCompleted": "0" // Mark as incomplete initially
    });
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
    DatabaseReference refRooms = FirebaseDatabase.instance
        .ref("App")
        .child("Rooms")
        .child(estateId)
        .child(roomName);

    await refRooms.set({
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

  // New method to mark estate as completed
  Future<void> markEstateAsCompleted(String type, String idEstate) async {
    await ref.child(type).child(idEstate).update({"IsCompleted": "1"});
  }
}
