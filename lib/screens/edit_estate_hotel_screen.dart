// File: edit_estate_screen.dart

// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:daimond_host_provider/widgets/edit_barber.dart';
import 'package:daimond_host_provider/widgets/edit_coffee_music_services.dart';
import 'package:daimond_host_provider/widgets/edit_gym.dart';
import 'package:daimond_host_provider/widgets/edit_jacuzzi.dart';
import 'package:daimond_host_provider/widgets/edit_massage.dart';
import 'package:daimond_host_provider/widgets/edit_music_services.dart'; // Updated import
import 'package:daimond_host_provider/widgets/edit_kids_area.dart'; // New import
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/widgets/edit_additionals_type.dart';
import 'package:daimond_host_provider/widgets/edit_sessions_type.dart';
import 'package:daimond_host_provider/widgets/edit_smoking_area.dart';
import 'package:daimond_host_provider/widgets/edit_swimming_pool.dart';
import 'package:daimond_host_provider/widgets/edit_valet_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../utils/additional_facility.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/rooms.dart';
import '../utils/success_dialogue.dart';
import '../widgets/birthday_textform_field.dart';
import '../widgets/edit_entry_visibility.dart';
import '../widgets/edit_location_widget.dart';
import '../widgets/edit_restaurant_type_visibility.dart';
import '../widgets/room_type_visibility.dart';
import 'additional_facility_screen.dart';
import 'main_screen_content.dart';

/// Modified EditEstate Widget
class EditEstateHotel extends StatefulWidget {
  final Map objEstate;
  final List<Rooms> LstRooms;
  final String estateId;
  final String estateType;

  EditEstateHotel(
      {required this.objEstate,
      required this.LstRooms,
      required this.estateId,
      required this.estateType,
      Key? key})
      : super(key: key);

  @override
  _EditEstateHotelState createState() => _EditEstateHotelState();
}

class _EditEstateHotelState extends State<EditEstateHotel> {
  final ImagePicker imgpicker = ImagePicker();
  late LatLng _editedLocation;
  List<XFile>? imagefiles;
  List<XFile> newImageFiles = [];
  List<String> existingImageUrls = [];
  final ImagePicker imgPicker = ImagePicker();
  final FirebaseStorage storage = FirebaseStorage.instance;
  final TextEditingController facilityNameController = TextEditingController();
  final TextEditingController facilityNameArController =
      TextEditingController();
  final TextEditingController facilityPriceController = TextEditingController();

// List to hold additional facilities
  List<Additional> facilityList = [];
  // Text Controllers for Arabic and English information
  final TextEditingController arNameController = TextEditingController();
  final TextEditingController arBioController = TextEditingController();
  final TextEditingController enNameController = TextEditingController();
  final TextEditingController enBioController = TextEditingController();
  TextEditingController menuLinkController = TextEditingController();

  // Text Controllers for Location
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  // Controllers for Rooms (if still needed)
  final TextEditingController singleController = TextEditingController();
  final TextEditingController doubleController = TextEditingController();
  final TextEditingController suiteController = TextEditingController();
  final TextEditingController familyController = TextEditingController();

  final TextEditingController arBioSingleController = TextEditingController();
  final TextEditingController arBioDoubleController = TextEditingController();
  final TextEditingController arBioSuiteController = TextEditingController();
  final TextEditingController arBioFamilyController = TextEditingController();
  final TextEditingController enBioSingleController = TextEditingController();
  final TextEditingController enBioDoubleController = TextEditingController();
  final TextEditingController enBioSuiteController = TextEditingController();
  final TextEditingController enBioFamilyController = TextEditingController();

  final TextEditingController singleControllerID = TextEditingController();
  final TextEditingController doubleControllerID = TextEditingController();
  final TextEditingController suiteControllerID = TextEditingController();
  final TextEditingController familyControllerID = TextEditingController();
  final TextEditingController grandSuiteControllerID = TextEditingController();
  final TextEditingController businessSuiteControllerID =
      TextEditingController();

  // Room Availability Booleans
  bool single = false;
  bool doubleRoom = false; // Renamed to avoid conflict with Dart's 'double'
  bool suite = false;
  bool family = false;

  // Location Values
  String? countryValue;
  String? stateValue;
  String? cityValue;

  // Firebase Reference
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref("App").child("Estate");

  // Lists to manage selected types and entries
  List<String> selectedRestaurantTypes = [];
  List<String> selectedEntries = [];
  List<String> selectedEditSessionsType = [];
  List<String> selectedEditAdditionalsType = [];
  List<String> lstMusicCoffee = [];

  // State Variables
  bool isMusicSelected = false;
  bool hasKidsArea = false; // New state variable
  bool hasSwimmingPoolSelected = false;
  bool hasJacuzziSelected = false;
  bool hasBarberSelected = false;
  bool hasMassageSelected = false;
  bool hasGymSelected = false;
  bool isSmokingAllowed = false;
  bool hasValet = false;
  bool valetWithFees = false;
  final TextEditingController grandSuiteController = TextEditingController();
  final TextEditingController grandSuiteControllerAr = TextEditingController();
  final TextEditingController businessSuiteController = TextEditingController();
  final TextEditingController businessSuiteControllerAr =
      TextEditingController();

  final TextEditingController singleControllerBioAr = TextEditingController();
  final TextEditingController doubleControllerBioAr = TextEditingController();
  final TextEditingController suiteControllerBioAr = TextEditingController();
  final TextEditingController familyControllerBioAr = TextEditingController();
  final TextEditingController singleControllerBioEn = TextEditingController();
  final TextEditingController doubleControllerBioEn = TextEditingController();
  final TextEditingController suiteControllerBioEn = TextEditingController();
  final TextEditingController familyControllerBioEn = TextEditingController();
  final TextEditingController grandSuiteControllerBioEn =
      TextEditingController();
  final TextEditingController grandSuiteControllerBioAr =
      TextEditingController();
  final TextEditingController businessSuiteControllerBioEn =
      TextEditingController();
  final TextEditingController businessSuiteControllerBioAr =
      TextEditingController();

  // Flags for room types

  bool grandSuite = false;
  bool businessSuite = false;
  late List<String> selectedRoomTypes = [];

  // Facility controllers and list (for additional facilities)

  @override
  void initState() {
    super.initState();
    String existingEntry = widget.objEstate['Entry'] ?? '';
    selectedRoomTypes = existingEntry
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Then check each known room type to see if it’s in selectedRoomTypes
    single = selectedRoomTypes.contains("Single");
    doubleRoom = selectedRoomTypes.contains("Double");
    suite = selectedRoomTypes.contains("Suite");
    family = selectedRoomTypes.contains("Hotel Apartments");
    grandSuite = selectedRoomTypes.contains("Grand Suite");
    businessSuite = selectedRoomTypes.contains("Business Suite");
    _fetchFacilities();
    print(
        "DEBUG: initState called. LstRooms length = ${widget.LstRooms.length}");
    double lat = double.tryParse(widget.objEstate["Lat"].toString()) ?? 37.7749;
    double lon =
        double.tryParse(widget.objEstate["Lon"].toString()) ?? -122.4194;
    _editedLocation = LatLng(lat, lon);
    // Initialize controllers with existing data
    _fetchEstateImages();
    arNameController.text = widget.objEstate["NameAr"] ?? '';
    arBioController.text = widget.objEstate["BioAr"] ?? '';
    enNameController.text = widget.objEstate["NameEn"] ?? '';
    enBioController.text = widget.objEstate["BioEn"] ?? '';
    menuLinkController.text = widget.objEstate["MenuLink"] ?? '';
    countryController.text = widget.objEstate["Country"] ?? '';
    cityController.text = widget.objEstate["City"] ?? '';
    stateController.text = widget.objEstate["State"] ?? '';
    countryValue = widget.objEstate["Country"];
    cityValue = widget.objEstate["City"];
    stateValue = widget.objEstate["State"];

    // Initialize selectedRestaurantTypes from objEstate if available
    // if (widget.objEstate.containsKey('TypeofRestaurant')) {
    //   String typeOfRestaurant = widget.objEstate['TypeofRestaurant'];
    //   selectedRestaurantTypes =
    //       typeOfRestaurant.split(',').map((e) => e.trim()).toList();
    // }
    if (widget.objEstate.containsKey('TypeofRestaurant')) {
      String typeOfRestaurant = widget.objEstate['TypeofRestaurant'];
      selectedRestaurantTypes = typeOfRestaurant
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Initialize selectedEntries from objEstate if available
    // if (widget.objEstate.containsKey('Entry')) {
    //   String entry = widget.objEstate['Entry'];
    //   selectedEntries = entry.split(',').map((e) => e.trim()).toList();
    // }
    if (widget.objEstate.containsKey('Entry')) {
      String entry = widget.objEstate['Entry'];
      selectedEntries = entry
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // if (widget.objEstate.containsKey('Sessions')) {
    //   String entry = widget.objEstate['Sessions'];
    //   selectedEditSessionsType = entry.split(',').map((e) => e.trim()).toList();
    // }
    if (widget.objEstate.containsKey('Sessions')) {
      String entry = widget.objEstate['Sessions'];
      selectedEditSessionsType = entry
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (widget.objEstate.containsKey('additionals')) {
      String entry = widget.objEstate['additionals'];
      selectedEditAdditionalsType =
          entry.split(',').map((e) => e.trim()).toList();
    }
    isMusicSelected = widget.objEstate["Music"] == "1";
    // if (widget.objEstate.containsKey('Lstmusic')) {
    //   String entry = widget.objEstate['Lstmusic'];
    //   lstMusicCoffee = entry.split(',').map((e) => e.trim()).toList();
    // }
    if (widget.objEstate.containsKey('Lstmusic')) {
      String entry = widget.objEstate['Lstmusic'];
      lstMusicCoffee = entry
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    hasKidsArea = widget.objEstate["HasKidsArea"] == "1"; // Initialize
    hasSwimmingPoolSelected =
        widget.objEstate["HasSwimmingPool"] == "1"; // Initialize
    hasBarberSelected = widget.objEstate["HasBarber"] == "1";
    hasGymSelected = widget.objEstate["HasGym"] == "1";
    hasJacuzziSelected = widget.objEstate["HasJacuzziInRoom"] == "1";
    hasMassageSelected = widget.objEstate["HasMassage"] == "1";
    isSmokingAllowed = widget.objEstate["IsSmokingAllowed"] == "1";
    hasValet = widget.objEstate["HasValet"] == "1";
    valetWithFees = widget.objEstate["ValetWithFees"] == "1";

    // Initialize Rooms data if still relevant
    for (var room in widget.LstRooms) {
      final rname = room.name.trim().toLowerCase();
      switch (rname) {
        case "single":
          single = true;
          singleController.text = room.price;
          singleControllerBioAr.text = room.bio; // from DB
          singleControllerBioEn.text = room.bioEn; // from DB
          singleControllerID.text = room.id; // if you want to preserve ID
          break;

        case "double":
          doubleRoom = true;
          doubleController.text = room.price;
          doubleControllerBioAr.text = room.bio;
          doubleControllerBioEn.text = room.bioEn;
          doubleControllerID.text = room.id;
          break;

        case "suite":
          suite = true;
          suiteController.text = room.price;
          suiteControllerBioAr.text = room.bio;
          suiteControllerBioEn.text = room.bioEn;
          suiteControllerID.text = room.id;
          break;

        case "hotel apartments":
          family = true;
          familyController.text = room.price;
          familyControllerBioAr.text = room.bio;
          familyControllerBioEn.text = room.bioEn;
          familyControllerID.text = room.id;
          break;

        case "grand suite":
          grandSuite = true;
          grandSuiteController.text = room.price;
          grandSuiteControllerBioAr.text = room.bio;
          grandSuiteControllerBioEn.text = room.bioEn;
          // If you also have an ID field
          grandSuiteControllerID.text = room.id;
          break;

        case "business suite":
          businessSuite = true;
          businessSuiteController.text = room.price;
          businessSuiteControllerBioAr.text = room.bio;
          businessSuiteControllerBioEn.text = room.bioEn;
          businessSuiteControllerID.text = room.id;
          break;

        default:
          // Handle unknown room name if needed
          break;
      }
    }
  }

  Future<void> _fetchFacilities() async {
    // DatabaseReference facilityRef = FirebaseDatabase.instance
    //     .ref("App")
    //     .child("Fasilty")
    //     .child(widget.estateId);
    //
    // final snapshot = await facilityRef.get();
    // if (snapshot.exists) {
    //   final data = snapshot.value as Map;
    //   data.forEach((facilityId, facilityData) {
    //     // Convert to Additional object
    //     Additional facility = Additional(
    //       id: facilityData["ID"] ?? "",
    //       name: facilityData["Name"] ?? "",
    //       nameEn: facilityData["NameEn"] ?? "",
    //       price: facilityData["Price"] ?? "",
    //       isBool: false,
    //       color: Colors.white,
    //     );
    //     facilityList.add(facility);
    //   });
    // }
    DatabaseReference refEstateFacility = FirebaseDatabase.instance
        .ref("App")
        .child("Estate")
        .child("Hottel")
        .child(widget.estateId)
        .child("Fasilty");
    final snapshots = await refEstateFacility.get();
    if (snapshots.exists) {
      final data = snapshots.value as Map;
      data.forEach((facilityId, facilityData) {
        // Convert to Additional object
        Additional facility = Additional(
          id: facilityData["ID"] ?? "",
          name: facilityData["Name"] ?? "",
          nameEn: facilityData["NameEn"] ?? "",
          price: facilityData["Price"] ?? "",
          isBool: false,
          color: Colors.white,
        );
        facilityList.add(facility);
      });
    }

    setState(() {}); // Trigger UI update
  }

  @override
  void dispose() {
    // Dispose room controllers
    singleController.dispose();
    doubleController.dispose();
    suiteController.dispose();
    familyController.dispose();
    grandSuiteController.dispose();
    grandSuiteControllerAr.dispose();
    businessSuiteController.dispose();
    businessSuiteControllerAr.dispose();

    singleControllerBioAr.dispose();
    doubleControllerBioAr.dispose();
    suiteControllerBioAr.dispose();
    familyControllerBioAr.dispose();
    singleControllerBioEn.dispose();
    doubleControllerBioEn.dispose();
    suiteControllerBioEn.dispose();
    familyControllerBioEn.dispose();
    grandSuiteControllerBioEn.dispose();
    grandSuiteControllerBioAr.dispose();
    businessSuiteControllerBioEn.dispose();
    businessSuiteControllerBioAr.dispose();

    // Dispose facility controllers
    facilityNameController.dispose();
    facilityNameArController.dispose();
    facilityPriceController.dispose();

    // Dispose any other controllers
    // ...
    super.dispose();
  }

  Future<void> _fetchEstateImages() async {
    try {
      ListResult result = await storage.ref("${widget.estateId}").listAll();
      List<String> urls = [];

      for (var item in result.items) {
        String url = await item.getDownloadURL();
        urls.add(url);
      }

      setState(() {
        existingImageUrls = urls;
      });
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  /// Pick new images
  Future<void> pickImages() async {
    try {
      final pickedFiles = await imgPicker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          newImageFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  /// Remove existing image from Firebase Storage
  Future<void> removeImage(String imageUrl) async {
    try {
      // Check if there is more than one image before allowing deletion
      if (existingImageUrls.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(getTranslated(context, "At least one image is required.")),
          ),
        );
        return; // Stop further execution
      }

      Reference ref = storage.refFromURL(imageUrl);
      await ref.delete();

      setState(() {
        existingImageUrls.remove(imageUrl);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(getTranslated(context, "Image removed successfully"))),
      );
    } catch (e) {
      print("Error removing image: $e");
    }
  }

  /// Upload new images to Firebase
  Future<List<String>> uploadNewImages() async {
    List<String> uploadedUrls = [];

    for (var image in newImageFiles) {
      try {
        Reference ref = storage.ref(
            "${widget.estateId}/${DateTime.now().millisecondsSinceEpoch}.jpg");
        UploadTask uploadTask = ref.putFile(File(image.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
    return uploadedUrls;
  }

  Future<List<String>> fetchExistingImages() async {
    List<String> existingImages = [];
    try {
      final storageRef = FirebaseStorage.instance.ref().child(widget.estateId);
      final ListResult result = await storageRef.listAll();

      for (var item in result.items) {
        existingImages.add(item.name);
      }

      // Sort the images numerically
      existingImages.sort((a, b) {
        int numA = int.tryParse(a.split('.').first) ?? 0;
        int numB = int.tryParse(b.split('.').first) ?? 0;
        return numA.compareTo(numB);
      });

      print("Existing images in storage: $existingImages");
      return existingImages;
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }

  /// Save updated images to Firebase
  Future<File> compressImage(File image) async {
    final result = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 800, // Adjust the width as per your requirement
      minHeight: 600, // Adjust the height as per your requirement
      quality: 80, // Compress quality (0 to 100)
    );

    final compressedFile = File(image.path)..writeAsBytesSync(result!);
    return compressedFile;
  }

  Future<void> saveUpdatedImages() async {
    try {
      // Show the custom loading dialog before the upload starts
      showCustomLoadingDialog(context);

      List<String> existingImages = await fetchExistingImages();
      int nextIndex = existingImages.isNotEmpty
          ? (int.tryParse(existingImages.last.split('.').first) ?? -1) + 1
          : 0;

      // Create a list of futures for concurrent uploads
      List<Future<String>> uploadFutures = [];

      for (var image in newImageFiles) {
        File compressedImage =
            await compressImage(File(image.path)); // Compress the image
        String newFileName = "$nextIndex.jpg"; // Generate new name
        final ref = FirebaseStorage.instance
            .ref()
            .child("${widget.estateId}/$newFileName");

        // Add the upload task to the futures list
        uploadFutures.add(ref.putFile(compressedImage).then((snapshot) {
          return snapshot.ref
              .getDownloadURL(); // Return download URL after upload
        }));

        nextIndex++; // Increment index for the next image
      }

      // Wait for all uploads to finish
      List<String> uploadedUrls = await Future.wait(uploadFutures);

      // Update UI with the new images URLs
      setState(() {
        newImageFiles.clear();
      });

      // Dismiss the loading dialog once the upload is complete
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(getTranslated(context, "Images updated successfully"))),
      );
    } catch (e) {
      print("Error saving images: $e");

      // Dismiss the loading dialog in case of error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(context, "Failed to update images"))),
      );
    }
  }

  /// Method to open image picker
  Future<void> openImages() async {
    try {
      var pickedfiles = await imgpicker.pickMultiImage();
      // You can use ImagePicker.camera for Camera capture
      if (pickedfiles != null && pickedfiles.isNotEmpty) {
        imagefiles = pickedfiles;
        print("Number of images selected: ${imagefiles?.length}");
        setState(() {});
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("Error while picking file: $e");
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String estateId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            getTranslated(context, "Delete Estate"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(getTranslated(context,
              "Are you sure you want to delete this estate? Deleting this estate will cause deleting all booking records, posts, and group chats.")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                getTranslated(context, "Cancel"),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close confirmation dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: kPurpleColor,
                      ),
                    );
                  },
                );

                await _deleteEstate(context, estateId);

                // Dismiss the progress dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                getTranslated(context, "Delete"),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEstate(BuildContext context, String estateId) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // Delete feedback associated with the specific estate
      DatabaseEvent feedbackEvent =
          await dbRef.child("App/CustomerFeedback").once();
      if (feedbackEvent.snapshot.value != null) {
        Map feedbacks = feedbackEvent.snapshot.value as Map;
        for (var feedbackEntry in feedbacks.entries) {
          var feedbackId = feedbackEntry.key;
          var feedbackData = feedbackEntry.value;
          if (feedbackData['EstateID'] == estateId) {
            await dbRef.child("App/CustomerFeedback/$feedbackId").remove();
          }
        }
      }

      // Delete chats associated with the specific estate
      await dbRef.child("App/EstateChats/$estateId").remove();

      // Delete the specific estate
      DatabaseEvent estateEvent = await dbRef.child("App/Estate").once();
      if (estateEvent.snapshot.value != null) {
        Map estates = estateEvent.snapshot.value as Map;
        for (var categoryEntry in estates.entries) {
          var category = categoryEntry.key;
          var items = categoryEntry.value;
          if (items is Map && items.containsKey(estateId)) {
            await dbRef.child("App/Estate/$category/$estateId").remove();
          }
        }
      }

      // Delete posts associated with the specific estate
      DatabaseEvent postsEvent = await dbRef.child("App/AllPosts").once();
      if (postsEvent.snapshot.value != null) {
        Map posts = postsEvent.snapshot.value as Map;
        for (var postEntry in posts.entries) {
          var postId = postEntry.key;
          var postData = postEntry.value;
          if (postData['EstateID'] == estateId) {
            await dbRef.child("App/AllPosts/$postId").remove();
          }
        }
      }

      // Delete booking requests associated with the specific estate
      DatabaseEvent bookingEvent = await dbRef.child("App/Booking/Book").once();
      if (bookingEvent.snapshot.value != null) {
        Map bookings = bookingEvent.snapshot.value as Map;
        for (var bookingEntry in bookings.entries) {
          var bookId = bookingEntry.key;
          var bookData = bookingEntry.value;
          if (bookData['EstateID'] == estateId) {
            await dbRef.child("App/Booking/Book/$bookId").remove();
          }
        }
      }

      // Navigate to the main screen content after successful deletion
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreenContent()));
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Error deleting estate")),
          ),
        );
      }
    }
  }

  bool validateSelection() {
    // For restaurant estates, ensure restaurant types, entries, and sessions are selected
    if (widget.estateType == "3") {
      if (selectedRestaurantTypes.isEmpty ||
          selectedEntries.isEmpty ||
          selectedEditSessionsType.isEmpty) {
        return false;
      }
    }
    // For coffee estates, ensure entries and sessions are selected
    else if (widget.estateType == "2") {
      if (selectedEntries.isEmpty || selectedEditSessionsType.isEmpty) {
        return false;
      }
    }
    // For hotel estates, ensure at least one room type (entry) is selected
    else if (widget.estateType == "1") {
      if (selectedRoomTypes.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Determine estate type
    String estateType = widget.objEstate['Type'] ?? "1"; // Default to "1"
    bool isLoading = existingImageUrls.isEmpty;

    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.delete, color: Colors.red),
      //       onPressed: () {
      //         _showDeleteConfirmationDialog(
      //             context, widget.objEstate['IDEstate']);
      //       },
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  SizedBox(height: 25),
                  TextHeader("Edit Estate Images"),
                  const SizedBox(height: 10),
                  // Button to Pick New Images

                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: pickImages,
                          icon: const Icon(
                            Icons
                                .add_a_photo, // You can use a gallery or camera icon
                            color:
                                kPurpleColor, // You can change this to any color that matches your design
                            size: 28, // Adjust the size as needed
                          ),
                          tooltip: getTranslated(context,
                              "Add New Images"), // Optional: tooltip for accessibility
                          splashColor: kPurpleColor
                              .withOpacity(0.2), // Optional: splash effect
                          highlightColor: kPurpleColor
                              .withOpacity(0.2), // Optional: highlight effect
                        ),
                        TextHeader("Add New Images"),
                      ],
                    ),
                  ),

                  // Display Existing Images
                  // Display Existing Images
                  if (existingImageUrls.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: existingImageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                width: 150,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: existingImageUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: InkWell(
                                  onTap: () =>
                                      removeImage(existingImageUrls[index]),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Shimmering Cloud Animation (Looks like an image loading)
                            Icon(
                              Icons.image,
                              color:
                                  kPurpleColor, // Use your preferred color here
                              size: 80, // Adjust size as needed
                            ),
                            const SizedBox(height: 20),
                            // Text that can be customized
                            Text(
                              getTranslated(context, "Loading images..."),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 20),
                            // Optional: More text for engaging message
                            Text(
                              getTranslated(context,
                                  "Please wait while we fetch your images"),
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Button to Pick New Images
                  // Button to Pick New Images
                  10.kH,
                  // Display Selected New Images
                  if (newImageFiles.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: newImageFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                width: 150,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.file(
                                  File(newImageFiles[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      newImageFiles.removeAt(index);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  // Save Changes Button
                  // const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: saveUpdatedImages,
                  //   child: Text(getTranslated(context, "Save Images")),
                  // ),
                  TextHeader("Information in Arabic"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormFieldStyle(
                      context: context,
                      hint: getTranslated(context, "Name"),
                      icon: Icon(
                        Icons.person,
                        color: kPurpleColor,
                      ),
                      control: arNameController,
                      readOnly: true,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return getTranslated(
                              context, "Estate's name in arabic is missing");
                        }
                        return null;
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormFieldStyle(
                      context: context,
                      hint: "Bio",
                      icon: Icon(
                        Icons.info,
                        color: kPurpleColor,
                      ),
                      control: arBioController,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.multiline,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextHeader("Information in English"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormFieldStyle(
                      context: context,
                      hint: getTranslated(context, "Name"),
                      icon: Icon(
                        Icons.person,
                        color: kPurpleColor,
                      ),
                      control: enNameController,
                      isObsecured: false,
                      validate: true,
                      readOnly: true,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormFieldStyle(
                      context: context,
                      hint: "Bio",
                      icon: Icon(
                        Icons.info,
                        color: kPurpleColor,
                      ),
                      control: enBioController,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.multiline,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextHeader("Menu"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormFieldStyle(
                      context: context,
                      hint: getTranslated(context, "Enter Menu Link"),
                      icon: Icon(
                        Icons.person,
                        color: kPurpleColor,
                      ),
                      control: menuLinkController,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextHeader("Edit Estate Location"),
                  EditLocationSection(
                    initialLocation: _editedLocation,
                    onLocationChanged: (newLocation) {
                      setState(() {
                        _editedLocation = newLocation;
                      });
                    },
                  ),

                  40.kH,
                  TextHeader("Location information"),
                  const SizedBox(height: 20),
                  ChooseCity(),
                  Visibility(
                    visible: estateType != "3",
                    child: SizedBox(height: 40),
                  ),

                  /// Display EntryVisibility for Type "2" and "3"

                  /// Display Music Services based on Type
                  if (estateType == "2") ...[
                    // For Type "2" (Coffee), allow additional music options
                    EditCoffeeMusicServices(
                      isVisible: true,
                      initialSelectedEntries: isMusicSelected
                          ? lstMusicCoffee.isNotEmpty
                              ? ["Is there music", ...lstMusicCoffee]
                              : []
                          : [],
                      onCheckboxChanged: (bool isChecked, String label) {
                        setState(() {
                          if (label == "Is there music") {
                            isMusicSelected = isChecked;
                            if (!isChecked) {
                              lstMusicCoffee
                                  .clear(); // Clear music list if disabled
                            }
                          } else {
                            if (isChecked) {
                              lstMusicCoffee.add(label);
                            } else {
                              lstMusicCoffee.remove(label);
                            }
                          }
                        });
                      },
                    ),
                  ] else if (estateType == "1" || estateType == "3") ...[
                    // For Type "1" (Hotel) and Type "3" (Restaurant), only show "Is there music"
                    EditMusicServices(
                      isVisible: true,
                      allowAdditionalOptions: false, // Disable extra options
                      initialSelectedEntries:
                          isMusicSelected ? ["Is there music"] : [],
                      onCheckboxChanged: (bool isChecked, String label) {
                        setState(() {
                          if (label == "Is there music") {
                            isMusicSelected = isChecked;
                          }
                        });
                      },
                    ),
                  ],

                  /// Display RestaurantTypeVisibility for Type "3"
                  Visibility(
                    visible: estateType == "1",
                    child: Column(
                      children: [
                        TextHeader("Hotel Amenities"),
                        EditSwimmingPool(
                          isVisible: true,
                          hasSwimmingPool: hasSwimmingPoolSelected,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasSwimmingPoolSelected = isChecked;
                            });
                          },
                        ),
                        EditJacuzzi(
                          isVisible: true,
                          hasJacuzzi: hasJacuzziSelected,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasJacuzziSelected = isChecked;
                            });
                          },
                        ),
                        EditBarber(
                          isVisible: true,
                          hasBarber: hasBarberSelected,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasBarberSelected = isChecked;
                            });
                          },
                        ),
                        EditMassage(
                          isVisible: true,
                          hasMassage: hasMassageSelected,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasMassageSelected = isChecked;
                            });
                          },
                        ),
                        EditGym(
                          isVisible: true,
                          hasGym: hasGymSelected,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasGymSelected = isChecked;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  40.kH,
                  Visibility(
                    visible: estateType == "3" || estateType == "2",
                    child: Column(
                      children: [
                        TextHeader(
                          "Smoking Area?",
                        ),
                        EditSmokingArea(
                          isVisible: true,
                          hasSmokingArea: isSmokingAllowed,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              isSmokingAllowed = isChecked;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      TextHeader(
                        "Smoking Area?",
                      ),
                      EditSmokingArea(
                        isVisible: true,
                        hasSmokingArea: isSmokingAllowed,
                        onCheckboxChanged: (bool isChecked) {
                          setState(() {
                            isSmokingAllowed = isChecked;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 40),
                  Column(
                    children: [
                      TextHeader(
                        "Valet Options",
                      ),
                      EditValetOptions(
                        isVisible: true,
                        hasValet: hasValet,
                        valetWithFees: valetWithFees,
                        onCheckboxChanged: (bool isChecked) {
                          setState(() {
                            hasValet = isChecked;
                            if (!hasValet) {
                              valetWithFees = false;
                            }
                          });
                        },
                        onValetFeesChanged: (bool isChecked) {
                          setState(() {
                            valetWithFees = isChecked;
                          });
                        },
                      ),
                    ],
                  ),
                  40.kH,

                  // Replace the existing "What We have?" section with the reusable RoomTypeVisibility widget:
                  RoomTypeVisibility(
                    userType: "1",
                    // Pass room selection flags and controllers
                    single: single,
                    double: doubleRoom,
                    suite: suite,
                    family: family,
                    grandSuite: grandSuite,
                    businessSuite: businessSuite,
                    singleHotelRoomController: singleController,
                    doubleHotelRoomController: doubleController,
                    suiteHotelRoomController: suiteController,
                    familyHotelRoomController: familyController,
                    grandSuiteController: grandSuiteController,
                    grandSuiteControllerAr: grandSuiteControllerAr,
                    businessSuiteController: businessSuiteController,
                    businessSuiteControllerAr: businessSuiteControllerAr,

                    // Existing bio controllers
                    singleHotelRoomControllerBioAr: singleControllerBioAr,
                    singleHotelRoomControllerBioEn: singleControllerBioEn,
                    doubleHotelRoomControllerBioEn: doubleControllerBioEn,
                    doubleHotelRoomControllerBioAr: doubleControllerBioAr,
                    suiteHotelRoomControllerBioEn: suiteControllerBioEn,
                    suiteHotelRoomControllerBioAr: suiteControllerBioAr,
                    familyHotelRoomControllerBioAr: familyControllerBioAr,
                    familyHotelRoomControllerBioEn: familyControllerBioEn,

                    // **Add the missing parameters below**:
                    grandSuiteControllerBioEn: grandSuiteControllerBioEn,
                    grandSuiteControllerBioAr: grandSuiteControllerBioAr,
                    businessSuiteControllerBioEn: businessSuiteControllerBioEn,
                    businessSuiteControllerBioAr: businessSuiteControllerBioAr,

                    // Callbacks
                    onSingleChanged: (value) {
                      setState(() {
                        single = value;
                        if (single) {
                          // If user just checked "Single" and it’s not already in the list
                          if (!selectedRoomTypes.contains("Single")) {
                            selectedRoomTypes.add("Single");
                          }
                        } else {
                          // If user unchecked "Single," remove it
                          selectedRoomTypes.remove("Single");
                        }
                      });
                    },
                    onDoubleChanged: (value) {
                      setState(() {
                        doubleRoom = value;
                        if (doubleRoom) {
                          if (!selectedRoomTypes.contains("Double")) {
                            selectedRoomTypes.add("Double");
                          }
                        } else {
                          selectedRoomTypes.remove("Double");
                        }
                      });
                    },
                    onSuiteChanged: (value) {
                      setState(() {
                        suite = value;
                        if (suite) {
                          if (!selectedRoomTypes.contains("Suite")) {
                            selectedRoomTypes.add("Suite");
                          }
                        } else {
                          selectedRoomTypes.remove("Suite");
                        }
                      });
                    },
                    onFamilyChanged: (value) {
                      setState(() {
                        family = value;
                        if (family) {
                          // For “Hotel Apartments,” or “Family,”
                          // be consistent with how you stored it in DB:
                          if (!selectedRoomTypes.contains("Hotel Apartments")) {
                            selectedRoomTypes.add("Hotel Apartments");
                          }
                        } else {
                          selectedRoomTypes.remove("Hotel Apartments");
                        }
                      });
                    },
                    onGrandChanged: (value) {
                      setState(() {
                        grandSuite = value;
                        if (grandSuite) {
                          if (!selectedRoomTypes.contains("Grand Suite")) {
                            selectedRoomTypes.add("Grand Suite");
                          }
                        } else {
                          selectedRoomTypes.remove("Grand Suite");
                        }
                      });
                    },
                    onBusinessChanged: (value) {
                      setState(() {
                        businessSuite = value;
                        if (businessSuite) {
                          if (!selectedRoomTypes.contains("Business Suite")) {
                            selectedRoomTypes.add("Business Suite");
                          }
                        } else {
                          selectedRoomTypes.remove("Business Suite");
                        }
                      });
                    },
                    onCheckboxChanged: (value, type) {
                      // Handle any extra checkboxes (like lounge options)
                    },
                    onBreakfastPriceChanged: (value) {
                      // ...
                    },
                    onLaunchPriceChanged: (value) {
                      // ...
                    },
                    onDinnerPriceChanged: (value) {
                      // ...
                    },
                  ),

// Immediately after, add the Additional Facilities section:
                  Visibility(
                    visible: true, // Always visible for hotel estates.
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: kDeepPurpleColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated(
                                context, "Additional Services (Optional)"),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: facilityNameController,
                            decoration: InputDecoration(
                              labelText: getTranslated(context, "Service Name"),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: facilityNameArController,
                            decoration: InputDecoration(
                              labelText:
                                  getTranslated(context, "Service Name Ar"),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: facilityPriceController,
                            decoration: InputDecoration(
                              labelText:
                                  getTranslated(context, "Service Price"),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (facilityNameController.text.isNotEmpty &&
                                  facilityNameArController.text.isNotEmpty &&
                                  facilityPriceController.text.isNotEmpty) {
                                String id = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();

                                Additional facility = Additional(
                                  id: id,
                                  name: facilityNameArController
                                      .text, // Arabic name
                                  nameEn: facilityNameController
                                      .text, // English name
                                  price: facilityPriceController.text,
                                  isBool: false,
                                  color: Colors.white,
                                );

                                // Add to the local list
                                setState(() {
                                  facilityList.add(facility);
                                });

                                // Write to Firebase under: App/Estate/Hottel/<estateId>/Fasilty/<facilityId>
                                final DatabaseReference facilityRef =
                                    FirebaseDatabase.instance
                                        .ref("App")
                                        .child("Estate")
                                        .child("Hottel")
                                        .child(widget.estateId)
                                        .child("Fasilty")
                                        .child(id);

                                await facilityRef.set({
                                  "ID": id,
                                  "Name": facility.name, // Arabic
                                  "NameEn": facility.nameEn, // English
                                  "Price": facility.price,
                                });

                                // Clear the text fields
                                facilityNameController.clear();
                                facilityNameArController.clear();
                                facilityPriceController.clear();

                                // Show a snackbar indicating the service was added
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated(
                                        context, "Service added successfully")),
                                  ),
                                );
                              }
                            },
                            child: Text(getTranslated(context, "Add Service")),
                          ),
                          const SizedBox(height: 10),
                          facilityList.isNotEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: facilityList.length,
                                  itemBuilder: (context, index) {
                                    final facility = facilityList[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                          Localizations.localeOf(context)
                                                      .languageCode ==
                                                  'ar'
                                              ? facility.name
                                              : facility.nameEn,
                                        ),
                                        subtitle: Text(facility.price),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () async {
                                            // Remove from the local list
                                            setState(() {
                                              facilityList.removeAt(index);
                                            });

                                            // Remove from Firebase
                                            final DatabaseReference
                                                facilityRef = FirebaseDatabase
                                                    .instance
                                                    .ref("App")
                                                    .child("Estate")
                                                    .child("Hottel")
                                                    .child(widget.estateId)
                                                    .child("Fasilty")
                                                    .child(facility.id);

                                            await facilityRef.remove();

                                            // Show a snackbar indicating the service was deleted
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(getTranslated(
                                                    context,
                                                    "Service deleted successfully")),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),

          /// Additional sections can go here...
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    child: Container(
                      width: 150.w,
                      height: 6.h,
                      margin: const EdgeInsets.only(
                          right: 20, left: 20, bottom: 20),
                      decoration: BoxDecoration(
                        color: kPurpleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context, "Save"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    onTap: () async {
                      // First check if the entry validation is successful
                      bool isEntryValid =
                          validateSelection(); // Check if any entry is selected
                      if (!isEntryValid) {
                        // Show validation message for required selection
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const FailureDialog(
                              text: "Incomplete Entry",
                              text1: "Select at least 1 Hotel Room!",
                            );
                          },
                        );
                        return; // Prevent further action if validation fails
                      }

                      // Determine the current estate type
                      String estateType =
                          widget.objEstate['Type'] ?? "1"; // Default to "1"

                      // Show custom loading dialog
                      showCustomLoadingDialog(context);

                      // Step 1: Check if any estate fields were changed
                      bool changesMade = false;

                      // Compare simple text and location fields
                      if (arNameController.text !=
                              (widget.objEstate["NameAr"] ?? '') ||
                          enNameController.text !=
                              (widget.objEstate["NameEn"] ?? '') ||
                          arBioController.text !=
                              (widget.objEstate["BioAr"] ?? '') ||
                          enBioController.text !=
                              (widget.objEstate["BioEn"] ?? '') ||
                          menuLinkController.text !=
                              (widget.objEstate["MenuLink"] ?? '') ||
                          countryValue != (widget.objEstate["Country"] ?? '') ||
                          cityValue != (widget.objEstate["City"] ?? '') ||
                          stateValue != (widget.objEstate["State"] ?? '') ||
                          _editedLocation.latitude !=
                              double.tryParse(
                                  widget.objEstate["Lat"].toString()) ||
                          _editedLocation.longitude !=
                              double.tryParse(
                                  widget.objEstate["Lon"].toString())) {
                        changesMade = true;
                      }

                      // Compare list/boolean fields relevant for all estate types
                      if ((estateType == "3" &&
                              selectedRestaurantTypes.join(",") !=
                                  (widget.objEstate["TypeofRestaurant"] ??
                                      '')) ||
                          (selectedEntries.join(",") !=
                              (widget.objEstate["Entry"] ?? '')) ||
                          ((estateType == "2" || estateType == "3") &&
                              selectedEditSessionsType.join(",") !=
                                  (widget.objEstate["Sessions"] ?? '')) ||
                          ((estateType == "2" || estateType == "3") &&
                              selectedEditAdditionalsType.join(",") !=
                                  (widget.objEstate["additionals"] ?? '')) ||
                          ((isMusicSelected ? "1" : "0") !=
                              (widget.objEstate["Music"] ?? "0")) ||
                          (lstMusicCoffee.join(",") !=
                              (widget.objEstate["Lstmusic"] ?? '')) ||
                          ((hasKidsArea ? "1" : "0") !=
                              (widget.objEstate["HasKidsArea"] ?? "0")) ||
                          ((hasSwimmingPoolSelected ? "1" : "0") !=
                              (widget.objEstate["HasSwimmingPool"] ?? "0")) ||
                          ((hasBarberSelected ? "1" : "0") !=
                              (widget.objEstate["HasBarber"] ?? "0")) ||
                          ((hasGymSelected ? "1" : "0") !=
                              (widget.objEstate["HasGym"] ?? "0")) ||
                          ((hasJacuzziSelected ? "1" : "0") !=
                              (widget.objEstate["HasJacuzziInRoom"] ?? "0")) ||
                          ((hasMassageSelected ? "1" : "0") !=
                              (widget.objEstate["HasMassage"] ?? "0")) ||
                          ((isSmokingAllowed ? "1" : "0") !=
                              (widget.objEstate["IsSmokingAllowed"] ?? "0")) ||
                          ((hasValet ? "1" : "0") !=
                              (widget.objEstate["HasValet"] ?? "0")) ||
                          ((valetWithFees ? "1" : "0") !=
                              (widget.objEstate["ValetWithFees"] ?? "0"))) {
                        changesMade = true;
                      }

                      // --- NEW: Compare room toggles and data with what's in widget.LstRooms ---
                      Rooms? findRoom(String lowerName) {
                        try {
                          return widget.LstRooms.firstWhere(
                              (r) => r.name.trim().toLowerCase() == lowerName);
                        } catch (e) {
                          return null;
                        }
                      }

                      // SINGLE
                      bool oldSingle = widget.LstRooms.any(
                          (r) => r.name.trim().toLowerCase() == "single");
                      Rooms? singleRoom = findRoom("single");
                      if (single != oldSingle) {
                        changesMade = true;
                      } else if (single && singleRoom != null) {
                        if (singleController.text != singleRoom.price ||
                            singleControllerBioAr.text != singleRoom.bio ||
                            singleControllerBioEn.text != singleRoom.bioEn ||
                            singleControllerID.text != singleRoom.id) {
                          changesMade = true;
                        }
                      } else if (single && singleRoom == null) {
                        changesMade = true;
                      }

                      // DOUBLE
                      bool oldDouble = widget.LstRooms.any(
                          (r) => r.name.trim().toLowerCase() == "double");
                      Rooms? doubleRoomData = findRoom("double");
                      if (doubleRoom != oldDouble) {
                        changesMade = true;
                      } else if (doubleRoom && doubleRoomData != null) {
                        if (doubleController.text != doubleRoomData.price ||
                            doubleControllerBioAr.text != doubleRoomData.bio ||
                            doubleControllerBioEn.text !=
                                doubleRoomData.bioEn ||
                            doubleControllerID.text != doubleRoomData.id) {
                          changesMade = true;
                        }
                      } else if (doubleRoom && doubleRoomData == null) {
                        changesMade = true;
                      }

                      // SUITE
                      bool oldSuite = widget.LstRooms.any(
                          (r) => r.name.trim().toLowerCase() == "suite");
                      Rooms? suiteRoom = findRoom("suite");
                      if (suite != oldSuite) {
                        changesMade = true;
                      } else if (suite && suiteRoom != null) {
                        if (suiteController.text != suiteRoom.price ||
                            suiteControllerBioAr.text != suiteRoom.bio ||
                            suiteControllerBioEn.text != suiteRoom.bioEn ||
                            suiteControllerID.text != suiteRoom.id) {
                          changesMade = true;
                        }
                      } else if (suite && suiteRoom == null) {
                        changesMade = true;
                      }

                      // HOTEL APARTMENTS / FAMILY
                      bool oldFamily = widget.LstRooms.any((r) =>
                          r.name.trim().toLowerCase() == "hotel apartments");
                      Rooms? familyRoom = findRoom("hotel apartments");
                      if (family != oldFamily) {
                        changesMade = true;
                      } else if (family && familyRoom != null) {
                        if (familyController.text != familyRoom.price ||
                            familyControllerBioAr.text != familyRoom.bio ||
                            familyControllerBioEn.text != familyRoom.bioEn ||
                            familyControllerID.text != familyRoom.id) {
                          changesMade = true;
                        }
                      } else if (family && familyRoom == null) {
                        changesMade = true;
                      }

                      // GRAND SUITE
                      bool oldGrandSuite = widget.LstRooms.any(
                          (r) => r.name.trim().toLowerCase() == "grand suite");
                      Rooms? grandSuiteRoom = findRoom("grand suite");
                      if (grandSuite != oldGrandSuite) {
                        changesMade = true;
                      } else if (grandSuite && grandSuiteRoom != null) {
                        if (grandSuiteController.text != grandSuiteRoom.price ||
                            grandSuiteControllerBioAr.text !=
                                grandSuiteRoom.bio ||
                            grandSuiteControllerBioEn.text !=
                                grandSuiteRoom.bioEn ||
                            grandSuiteControllerID.text != grandSuiteRoom.id) {
                          changesMade = true;
                        }
                      } else if (grandSuite && grandSuiteRoom == null) {
                        changesMade = true;
                      }

                      // BUSINESS SUITE
                      bool oldBusinessSuite = widget.LstRooms.any((r) =>
                          r.name.trim().toLowerCase() == "business suite");
                      Rooms? businessSuiteRoom = findRoom("business suite");
                      if (businessSuite != oldBusinessSuite) {
                        changesMade = true;
                      } else if (businessSuite && businessSuiteRoom != null) {
                        if (businessSuiteController.text !=
                                businessSuiteRoom.price ||
                            businessSuiteControllerBioAr.text !=
                                businessSuiteRoom.bio ||
                            businessSuiteControllerBioEn.text !=
                                businessSuiteRoom.bioEn ||
                            businessSuiteControllerID.text !=
                                businessSuiteRoom.id) {
                          changesMade = true;
                        }
                      } else if (businessSuite && businessSuiteRoom == null) {
                        changesMade = true;
                      }

                      // Check if new images were added
                      if (newImageFiles.isNotEmpty) {
                        changesMade = true;
                      }

                      // Step 2: Process changes based on the flag
                      if (changesMade) {
                        await Update();

                        if (newImageFiles.isNotEmpty) {
                          await saveUpdatedImages();
                        }

                        // Dismiss the loading dialog
                        Navigator.pop(context);

                        // Show success dialog
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const SuccessDialog(
                              text: "Success",
                              text1:
                                  "Your estate has been successfully updated.",
                            );
                          },
                        );

                        if (estateType == "1") {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      } else {
                        // Dismiss the loading dialog
                        Navigator.pop(context);

                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const FailureDialog(
                              text: "No Changes Detected",
                              text1:
                                  "You did not make any changes to your estate.",
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Row(
          //     children: [
          //       Expanded(
          //         flex: 3,
          //         child: InkWell(
          //           child: Container(
          //             width: 150.w,
          //             height: 6.h,
          //             margin: const EdgeInsets.only(
          //                 right: 20, left: 20, bottom: 20),
          //             decoration: BoxDecoration(
          //               color: kPurpleColor,
          //               borderRadius: BorderRadius.circular(12),
          //             ),
          //             child: Center(
          //               child: Text(
          //                 getTranslated(context, "Save"),
          //                 style: const TextStyle(color: Colors.white),
          //               ),
          //             ),
          //           ),
          //           onTap: () async {
          //             // First check if the entry validation is successful
          //             bool isEntryValid =
          //                 validateSelection(); // Check if any entry is selected
          //
          //             if (!isEntryValid) {
          //               // Show validation message for required selection
          //               showDialog(
          //                 context: context,
          //                 builder: (BuildContext context) {
          //                   return const FailureDialog(
          //                     text: "Incomplete Entry",
          //                     text1: "Select at least 1 Hotel Room!",
          //                   );
          //                 },
          //               );
          //               return; // Prevent further action if validation fails
          //             }
          //
          //             // Determine the current estate type
          //             String estateType =
          //                 widget.objEstate['Type'] ?? "1"; // Default to "1"
          //
          //             // Step 1: Check if any estate fields were changed
          //             bool changesMade = false;
          //
          //             // Compare simple text and location fields
          //             if (arNameController.text !=
          //                     (widget.objEstate["NameAr"] ?? '') ||
          //                 enNameController.text !=
          //                     (widget.objEstate["NameEn"] ?? '') ||
          //                 arBioController.text !=
          //                     (widget.objEstate["BioAr"] ?? '') ||
          //                 enBioController.text !=
          //                     (widget.objEstate["BioEn"] ?? '') ||
          //                 menuLinkController.text !=
          //                     (widget.objEstate["MenuLink"] ?? '') ||
          //                 countryValue != (widget.objEstate["Country"] ?? '') ||
          //                 cityValue != (widget.objEstate["City"] ?? '') ||
          //                 stateValue != (widget.objEstate["State"] ?? '') ||
          //                 _editedLocation.latitude !=
          //                     double.tryParse(
          //                         widget.objEstate["Lat"].toString()) ||
          //                 _editedLocation.longitude !=
          //                     double.tryParse(
          //                         widget.objEstate["Lon"].toString())) {
          //               changesMade = true;
          //             }
          //
          //             // Compare list/boolean fields relevant for all estate types
          //             if ((estateType == "3" &&
          //                     selectedRestaurantTypes.join(",") !=
          //                         (widget.objEstate["TypeofRestaurant"] ??
          //                             '')) ||
          //                 (selectedEntries.join(",") !=
          //                     (widget.objEstate["Entry"] ?? '')) ||
          //                 ((estateType == "2" || estateType == "3") &&
          //                     selectedEditSessionsType.join(",") !=
          //                         (widget.objEstate["Sessions"] ?? '')) ||
          //                 ((estateType == "2" || estateType == "3") &&
          //                     selectedEditAdditionalsType.join(",") !=
          //                         (widget.objEstate["additionals"] ?? '')) ||
          //                 ((isMusicSelected ? "1" : "0") !=
          //                     (widget.objEstate["Music"] ?? "0")) ||
          //                 (lstMusicCoffee.join(",") !=
          //                     (widget.objEstate["Lstmusic"] ?? '')) ||
          //                 ((hasKidsArea ? "1" : "0") !=
          //                     (widget.objEstate["HasKidsArea"] ?? "0")) ||
          //                 ((hasSwimmingPoolSelected ? "1" : "0") !=
          //                     (widget.objEstate["HasSwimmingPool"] ?? "0")) ||
          //                 ((hasBarberSelected ? "1" : "0") !=
          //                     (widget.objEstate["HasBarber"] ?? "0")) ||
          //                 ((hasGymSelected ? "1" : "0") !=
          //                     (widget.objEstate["HasGym"] ?? "0")) ||
          //                 ((hasJacuzziSelected ? "1" : "0") !=
          //                     (widget.objEstate["HasJacuzziInRoom"] ?? "0")) ||
          //                 ((hasMassageSelected ? "1" : "0") !=
          //                     (widget.objEstate["HasMassage"] ?? "0")) ||
          //                 ((isSmokingAllowed ? "1" : "0") !=
          //                     (widget.objEstate["IsSmokingAllowed"] ?? "0")) ||
          //                 ((hasValet ? "1" : "0") !=
          //                     (widget.objEstate["HasValet"] ?? "0")) ||
          //                 ((valetWithFees ? "1" : "0") !=
          //                     (widget.objEstate["ValetWithFees"] ?? "0"))) {
          //               changesMade = true;
          //             }
          //
          //             // --- NEW: Compare room toggles and data with what's in widget.LstRooms ---
          //
          //             // Helper to safely find a room in widget.LstRooms
          //             Rooms? findRoom(String lowerName) {
          //               try {
          //                 return widget.LstRooms.firstWhere(
          //                   (r) => r.name.trim().toLowerCase() == lowerName,
          //                 );
          //               } catch (e) {
          //                 return null;
          //               }
          //             }
          //
          //             // SINGLE
          //             bool oldSingle = widget.LstRooms.any(
          //               (r) => r.name.trim().toLowerCase() == "single",
          //             );
          //             Rooms? singleRoom = findRoom("single");
          //             // If single is toggled differently, or if data changed
          //             if (single != oldSingle) {
          //               changesMade = true;
          //             } else if (single && singleRoom != null) {
          //               if (singleController.text != singleRoom.price ||
          //                   singleControllerBioAr.text != singleRoom.bio ||
          //                   singleControllerBioEn.text != singleRoom.bioEn ||
          //                   singleControllerID.text != singleRoom.id) {
          //                 changesMade = true;
          //               }
          //             } else if (single && singleRoom == null) {
          //               // Means user added "Single" brand-new
          //               changesMade = true;
          //             }
          //
          //             // DOUBLE
          //             bool oldDouble = widget.LstRooms.any(
          //               (r) => r.name.trim().toLowerCase() == "double",
          //             );
          //             Rooms? doubleRoomData = findRoom("double");
          //             if (doubleRoom != oldDouble) {
          //               changesMade = true;
          //             } else if (doubleRoom && doubleRoomData != null) {
          //               if (doubleController.text != doubleRoomData.price ||
          //                   doubleControllerBioAr.text != doubleRoomData.bio ||
          //                   doubleControllerBioEn.text !=
          //                       doubleRoomData.bioEn ||
          //                   doubleControllerID.text != doubleRoomData.id) {
          //                 changesMade = true;
          //               }
          //             } else if (doubleRoom && doubleRoomData == null) {
          //               changesMade = true;
          //             }
          //
          //             // SUITE
          //             bool oldSuite = widget.LstRooms.any(
          //               (r) => r.name.trim().toLowerCase() == "suite",
          //             );
          //             Rooms? suiteRoom = findRoom("suite");
          //             if (suite != oldSuite) {
          //               changesMade = true;
          //             } else if (suite && suiteRoom != null) {
          //               if (suiteController.text != suiteRoom.price ||
          //                   suiteControllerBioAr.text != suiteRoom.bio ||
          //                   suiteControllerBioEn.text != suiteRoom.bioEn ||
          //                   suiteControllerID.text != suiteRoom.id) {
          //                 changesMade = true;
          //               }
          //             } else if (suite && suiteRoom == null) {
          //               changesMade = true;
          //             }
          //
          //             // HOTEL APARTMENTS / FAMILY
          //             bool oldFamily = widget.LstRooms.any(
          //               (r) =>
          //                   r.name.trim().toLowerCase() == "hotel apartments",
          //             );
          //             Rooms? familyRoom = findRoom("hotel apartments");
          //             if (family != oldFamily) {
          //               changesMade = true;
          //             } else if (family && familyRoom != null) {
          //               if (familyController.text != familyRoom.price ||
          //                   familyControllerBioAr.text != familyRoom.bio ||
          //                   familyControllerBioEn.text != familyRoom.bioEn ||
          //                   familyControllerID.text != familyRoom.id) {
          //                 changesMade = true;
          //               }
          //             } else if (family && familyRoom == null) {
          //               changesMade = true;
          //             }
          //
          //             // GRAND SUITE
          //             bool oldGrandSuite = widget.LstRooms.any(
          //               (r) => r.name.trim().toLowerCase() == "grand suite",
          //             );
          //             Rooms? grandSuiteRoom = findRoom("grand suite");
          //             if (grandSuite != oldGrandSuite) {
          //               changesMade = true;
          //             } else if (grandSuite && grandSuiteRoom != null) {
          //               if (grandSuiteController.text != grandSuiteRoom.price ||
          //                   grandSuiteControllerBioAr.text !=
          //                       grandSuiteRoom.bio ||
          //                   grandSuiteControllerBioEn.text !=
          //                       grandSuiteRoom.bioEn ||
          //                   grandSuiteControllerID.text != grandSuiteRoom.id) {
          //                 changesMade = true;
          //               }
          //             } else if (grandSuite && grandSuiteRoom == null) {
          //               changesMade = true;
          //             }
          //
          //             // BUSINESS SUITE
          //             bool oldBusinessSuite = widget.LstRooms.any(
          //               (r) => r.name.trim().toLowerCase() == "business suite",
          //             );
          //             Rooms? businessSuiteRoom = findRoom("business suite");
          //             if (businessSuite != oldBusinessSuite) {
          //               changesMade = true;
          //             } else if (businessSuite && businessSuiteRoom != null) {
          //               if (businessSuiteController.text !=
          //                       businessSuiteRoom.price ||
          //                   businessSuiteControllerBioAr.text !=
          //                       businessSuiteRoom.bio ||
          //                   businessSuiteControllerBioEn.text !=
          //                       businessSuiteRoom.bioEn ||
          //                   businessSuiteControllerID.text !=
          //                       businessSuiteRoom.id) {
          //                 changesMade = true;
          //               }
          //             } else if (businessSuite && businessSuiteRoom == null) {
          //               changesMade = true;
          //             }
          //
          //             // Check if new images were added
          //             if (newImageFiles.isNotEmpty) {
          //               changesMade =
          //                   true; // Mark as changes made if new images are added
          //             }
          //
          //             // Step 2: Show appropriate dialog based on changes
          //             if (changesMade) {
          //               // If changes detected, update the estate
          //               await Update();
          //
          //               // Upload new images if any are selected
          //               if (newImageFiles.isNotEmpty) {
          //                 await saveUpdatedImages(); // Upload the new images
          //               }
          //
          //               // Show success dialog
          //               await showDialog(
          //                 context: context,
          //                 builder: (BuildContext context) {
          //                   return const SuccessDialog(
          //                     text: "Success",
          //                     text1:
          //                         "Your estate has been successfully updated.",
          //                   );
          //                 },
          //               );
          //
          //               // Navigate based on estate type after success
          //               if (estateType == "1") {
          //                 Navigator.of(context)
          //                     .popUntil((route) => route.isFirst);
          //               }
          //             } else {
          //               // If no changes were made, show failure dialog without navigating away
          //               await showDialog(
          //                 context: context,
          //                 builder: (BuildContext context) {
          //                   return const FailureDialog(
          //                     text: "No Changes Detected",
          //                     text1:
          //                         "You did not make any changes to your estate.",
          //                   );
          //                 },
          //               );
          //             }
          //           },
          //
          //           // onTap: () async {
          //           //   // First check if the entry validation is successful
          //           //   bool isEntryValid =
          //           //       validateSelection(); // Check if any entry is selected
          //           //
          //           //   if (!isEntryValid) {
          //           //     // Show validation message for required selection
          //           //     showDialog(
          //           //       context: context,
          //           //       builder: (BuildContext context) {
          //           //         return const FailureDialog(
          //           //           text: "Incomplete Entry",
          //           //           text1: "Select at least 1!",
          //           //         );
          //           //       },
          //           //     );
          //           //     return; // Prevent further action if validation fails
          //           //   }
          //           //
          //           //   // Determine the current estate type
          //           //   String estateType =
          //           //       widget.objEstate['Type'] ?? "1"; // Default to "1"
          //           //
          //           //   // Step 1: Check if any estate fields were changed
          //           //   bool changesMade = false;
          //           //
          //           //   // Compare simple text and location fields
          //           //   if (arNameController.text !=
          //           //           (widget.objEstate["NameAr"] ?? '') ||
          //           //       enNameController.text !=
          //           //           (widget.objEstate["NameEn"] ?? '') ||
          //           //       arBioController.text !=
          //           //           (widget.objEstate["BioAr"] ?? '') ||
          //           //       enBioController.text !=
          //           //           (widget.objEstate["BioEn"] ?? '') ||
          //           //       menuLinkController.text !=
          //           //           (widget.objEstate["MenuLink"] ?? '') ||
          //           //       countryValue != (widget.objEstate["Country"] ?? '') ||
          //           //       cityValue != (widget.objEstate["City"] ?? '') ||
          //           //       stateValue != (widget.objEstate["State"] ?? '') ||
          //           //       _editedLocation.latitude !=
          //           //           double.tryParse(
          //           //               widget.objEstate["Lat"].toString()) ||
          //           //       _editedLocation.longitude !=
          //           //           double.tryParse(
          //           //               widget.objEstate["Lon"].toString())) {
          //           //     changesMade = true;
          //           //   }
          //           //
          //           //   // Compare list and boolean fields relevant for all estate types
          //           //   if ((estateType == "3" &&
          //           //           selectedRestaurantTypes.join(",") !=
          //           //               (widget.objEstate["TypeofRestaurant"] ??
          //           //                   '')) ||
          //           //       (selectedEntries.join(",") !=
          //           //           (widget.objEstate["Entry"] ?? '')) ||
          //           //       ((estateType == "2" || estateType == "3") &&
          //           //           selectedEditSessionsType.join(",") !=
          //           //               (widget.objEstate["Sessions"] ?? '')) ||
          //           //       ((estateType == "2" || estateType == "3") &&
          //           //           selectedEditAdditionalsType.join(",") !=
          //           //               (widget.objEstate["additionals"] ?? '')) ||
          //           //       ((isMusicSelected ? "1" : "0") !=
          //           //           (widget.objEstate["Music"] ?? "0")) ||
          //           //       (lstMusicCoffee.join(",") !=
          //           //           (widget.objEstate["Lstmusic"] ?? '')) ||
          //           //       ((hasKidsArea ? "1" : "0") !=
          //           //           (widget.objEstate["HasKidsArea"] ?? "0")) ||
          //           //       ((hasSwimmingPoolSelected ? "1" : "0") !=
          //           //           (widget.objEstate["HasSwimmingPool"] ?? "0")) ||
          //           //       ((hasBarberSelected ? "1" : "0") !=
          //           //           (widget.objEstate["HasBarber"] ?? "0")) ||
          //           //       ((hasGymSelected ? "1" : "0") !=
          //           //           (widget.objEstate["HasGym"] ?? "0")) ||
          //           //       ((hasJacuzziSelected ? "1" : "0") !=
          //           //           (widget.objEstate["HasJacuzziInRoom"] ?? "0")) ||
          //           //       ((hasMassageSelected ? "1" : "0") !=
          //           //           (widget.objEstate["HasMassage"] ?? "0")) ||
          //           //       ((isSmokingAllowed ? "1" : "0") !=
          //           //           (widget.objEstate["IsSmokingAllowed"] ?? "0")) ||
          //           //       ((hasValet ? "1" : "0") !=
          //           //           (widget.objEstate["HasValet"] ?? "0")) ||
          //           //       ((valetWithFees ? "1" : "0") !=
          //           //           (widget.objEstate["ValetWithFees"] ?? "0"))) {
          //           //     changesMade = true;
          //           //   }
          //           //
          //           //   // Check if new images were added
          //           //   if (newImageFiles.isNotEmpty) {
          //           //     changesMade =
          //           //         true; // Mark as changes made if new images are added
          //           //   }
          //           //
          //           //   // Step 2: Show appropriate dialog based on changes
          //           //   if (changesMade) {
          //           //     // If changes detected, update the estate
          //           //     await Update();
          //           //
          //           //     // Upload new images if any are selected
          //           //     if (newImageFiles.isNotEmpty) {
          //           //       await saveUpdatedImages(); // Upload the new images
          //           //     }
          //           //
          //           //     // Show success dialog
          //           //     await showDialog(
          //           //       context: context,
          //           //       builder: (BuildContext context) {
          //           //         return const SuccessDialog(
          //           //           text: "Success",
          //           //           text1:
          //           //               "Your estate has been successfully updated.",
          //           //         );
          //           //       },
          //           //     );
          //           //
          //           //     // Navigate based on estate type after success
          //           //     if (estateType == "1") {
          //           //       Navigator.of(context)
          //           //           .popUntil((route) => route.isFirst);
          //           //     }
          //           //   } else {
          //           //     // If no changes were made, show failure dialog without navigating away
          //           //     await showDialog(
          //           //       context: context,
          //           //       builder: (BuildContext context) {
          //           //         return const FailureDialog(
          //           //           text: "No Changes Detected",
          //           //           text1:
          //           //               "You did not make any changes to your estate.",
          //           //         );
          //           //       },
          //           //     );
          //           //   }
          //           // },
          //         ),
          //       )
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  /// Method to update estate information in Firebase
  Future<void> Update() async {
    // Figure out which Firebase child to update based on estateType
    String ChildType;
    String type;

    // Retrieve estateType from your widget or state
    String estateType = widget.objEstate['Type'] ?? "1";

    // Reference to /Rooms for the hotel
    DatabaseReference refRooms = FirebaseDatabase.instance.ref(
      "App/Estate/Hottel/${widget.objEstate['IDEstate'].toString()}/Rooms",
    );

    // --- 1. Update or Remove Individual Rooms ---

    // SINGLE
    if (single) {
      await refRooms.child("Single").update({
        "ID": "1",
        "Name": "Single",
        "Price": singleController.text,
        "BioAr": singleControllerBioAr.text,
        "BioEn": singleControllerBioEn.text,
      });
    } else {
      await refRooms.child("Single").remove();
    }

    // DOUBLE
    if (doubleRoom) {
      await refRooms.child("Double").update({
        "ID": "2",
        "Name": "Double",
        "Price": doubleController.text,
        "BioAr": doubleControllerBioAr.text,
        "BioEn": doubleControllerBioEn.text,
      });
    } else {
      await refRooms.child("Double").remove();
    }

    // SUITE
    if (suite) {
      await refRooms.child("Suite").update({
        "ID": "3",
        "Name": "Suite",
        "Price": suiteController.text,
        "BioAr": suiteControllerBioAr.text,
        "BioEn": suiteControllerBioEn.text,
      });
    } else {
      await refRooms.child("Suite").remove();
    }

    // FAMILY (often stored as "Hotel Apartments" in your DB)
    if (family) {
      await refRooms.child("Hotel Apartments").update({
        "ID": "4",
        "Name": "Hotel Apartments",
        "Price": familyController.text,
        "BioAr": familyControllerBioAr.text,
        "BioEn": familyControllerBioEn.text,
      });
    } else {
      await refRooms.child("Hotel Apartments").remove();
    }

    // GRAND SUITE
    if (grandSuite) {
      await refRooms.child("Grand Suite").update({
        "ID": "5",
        "Name": "Grand Suite",
        "Price": grandSuiteController.text,
        "BioAr": grandSuiteControllerBioAr.text,
        "BioEn": grandSuiteControllerBioEn.text,
      });
    } else {
      await refRooms.child("Grand Suite").remove();
    }

    // BUSINESS SUITE
    if (businessSuite) {
      await refRooms.child("Business Suite").update({
        "ID": "6",
        "Name": "Business Suite",
        "Price": businessSuiteController.text,
        "BioAr": businessSuiteControllerBioAr.text,
        "BioEn": businessSuiteControllerBioEn.text,
      });
    } else {
      await refRooms.child("Business Suite").remove();
    }

    // --- 2. Determine ChildType (Hottel / Coffee / Restaurant) ---
    if (estateType == "1") {
      ChildType = "Hottel"; // Keep spelling consistent with your DB
      type = "1";
    } else if (estateType == "2") {
      ChildType = "Coffee";
      type = "2";
    } else {
      ChildType = "Restaurant";
      type = "3";
    }

    // --- 3. Grab your shared pref TypeAccount if needed ---
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? TypeAccount = sharedPreferences.getString("TypeAccount") ?? "2";

    // --- 4. Determine Music or other toggles ---
    String musicValue = isMusicSelected ? "1" : "0";

    // --- 5. Rebuild "Entry" from the booleans so it’s always accurate ---
    List<String> updatedEntries = [];
    if (single) updatedEntries.add("Single");
    if (doubleRoom) updatedEntries.add("Double");
    if (suite) updatedEntries.add("Suite");
    if (family) updatedEntries.add("Hotel Apartments");
    if (grandSuite) updatedEntries.add("Grand Suite");
    if (businessSuite) updatedEntries.add("Business Suite");
    // Feel free to rename "Hotel Apartments" to "Family" if that’s how you store it

    // --- 6. Update the main Estate node ---
    await ref
        .child(ChildType)
        .child(widget.objEstate['IDEstate'].toString())
        .update({
      "NameAr": arNameController.text,
      "NameEn": enNameController.text,
      "BioAr": arBioController.text,
      "BioEn": enBioController.text,
      "MenuLink": menuLinkController.text,
      "Country": countryValue,
      "City": cityValue,
      "State": stateValue,
      "Type": type,
      "IDUser": FirebaseAuth.instance.currentUser?.uid ?? "No Id",
      "IDEstate": widget.objEstate['IDEstate'],
      "TypeAccount": TypeAccount,

      // Music + Additional Toggles
      "Music": musicValue,
      "HasKidsArea": hasKidsArea ? "1" : "0",
      "IsSmokingAllowed": isSmokingAllowed ? "1" : "0",
      "HasValet": hasValet ? "1" : "0",
      "ValetWithFees": valetWithFees ? "1" : "0",

      // Hotel-only toggles
      if (type == "1") "HasBarber": hasBarberSelected ? "1" : "0",
      if (type == "1") "HasGym": hasGymSelected ? "1" : "0",
      if (type == "1") "HasJacuzziInRoom": hasJacuzziSelected ? "1" : "0",
      if (type == "1") "HasMassage": hasMassageSelected ? "1" : "0",
      if (type == "1") "HasSwimmingPool": hasSwimmingPoolSelected ? "1" : "0",

      // Restaurant-only toggles
      if (type == "3") "TypeofRestaurant": selectedRestaurantTypes.join(","),

      // Updated latitude / longitude
      "Lat": _editedLocation.latitude,
      "Lon": _editedLocation.longitude,

      // Finally, the updated "Entry" field (our main addition)
      "Entry": updatedEntries.join(","),

      // For Coffee/Restaurant sessions
      if (type == "2" || type == "3")
        "Sessions": selectedEditSessionsType.join(","),

      // For Coffee/Restaurant additionals
      if (type == "2" || type == "3")
        "additionals": selectedEditAdditionalsType.join(","),

      // If type == "2", we have Lstmusic
      if (type == "2") "Lstmusic": lstMusicCoffee.join(","),
    });

    // Done!
  }

  /// Widget for choosing city using CSCPicker
  Widget ChooseCity() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 30),
      child: CSCPicker(
        /// Enable/disable state dropdown
        showStates: true,

        /// Enable/disable city dropdown
        showCities: true,

        /// Disable country flag
        flagState: CountryFlag.DISABLE,

        /// Dropdown decoration
        dropdownDecoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).brightness == Brightness.dark
                ? kDarkModeColor
                : Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1)),
        disabledDropdownDecoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.grey.shade300,
            border: Border.all(color: Colors.grey.shade300, width: 1)),

        /// Placeholders for dropdown search fields
        countrySearchPlaceholder: getTranslated(context, "Country"),
        stateSearchPlaceholder: getTranslated(context, "State"),
        citySearchPlaceholder: getTranslated(context, "City"),

        /// Labels for dropdowns
        countryDropdownLabel: countryController.text,
        stateDropdownLabel: stateController.text,
        cityDropdownLabel: cityController.text,

        /// Selected item style
        selectedItemStyle: const TextStyle(
          fontSize: 14,
        ),

        /// Dropdown dialog heading style
        dropdownHeadingStyle:
            const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),

        /// Dropdown dialog item style
        dropdownItemStyle: const TextStyle(
          fontSize: 14,
        ),

        /// Dialog box radius
        dropdownDialogRadius: 10.0,

        /// Search bar radius
        searchBarRadius: 10.0,

        /// Callback when country changes
        onCountryChanged: (value) {
          setState(() {
            countryValue = value;
          });
        },

        /// Callback when state changes
        onStateChanged: (value) {
          setState(() {
            stateValue = value;
          });
        },

        /// Callback when city changes
        onCityChanged: (value) {
          setState(() {
            cityValue = value;
          });
        },
      ),
    );
  }

  /// Helper method to create a close button for room types
  Widget closeTextFormFieldStyle(Function() fun) {
    return InkWell(
      onTap: fun,
      child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(blurRadius: 10, color: Colors.grey, spreadRadius: 1)
            ],
          ),
          child: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.close,
              color: Colors.red,
            ),
          )),
    );
  }

  /// Helper method to display headers
  Widget TextHeader(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 10),
      child: Text(
        getTranslated(context, text),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
