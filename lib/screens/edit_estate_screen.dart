import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:daimond_host_provider/screens/seat_map_builder_screen.dart';
import 'package:daimond_host_provider/widgets/edit_barber.dart';
import 'package:daimond_host_provider/widgets/edit_coffee_music_services.dart';
import 'package:daimond_host_provider/widgets/edit_gym.dart';
import 'package:daimond_host_provider/widgets/edit_jacuzzi.dart';
import 'package:daimond_host_provider/widgets/edit_massage.dart';
import 'package:daimond_host_provider/widgets/edit_music_services.dart';
import 'package:daimond_host_provider/widgets/edit_kids_area.dart';
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

import '../backend/adding_estate_services.dart';
import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/rooms.dart';
import '../utils/success_dialogue.dart';
import '../utils/under_process_dialog.dart';
import '../widgets/birthday_textform_field.dart';
import '../widgets/edit_entry_visibility.dart';
import '../widgets/edit_location_widget.dart';
import '../widgets/edit_restaurant_type_visibility.dart';
import 'additional_facility_screen.dart';
import 'main_screen_content.dart';

// METRO
import '../widgets/riyadh_metro_picker.dart';
import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart' as geo;

class EditEstate extends StatefulWidget {
  final Map objEstate;
  final List<Rooms> LstRooms;
  final String estateId;
  final String estateType;

  EditEstate({
    required this.objEstate,
    required this.LstRooms,
    required this.estateId,
    required this.estateType,
    Key? key,
  }) : super(key: key);

  @override
  _EditEstateState createState() => _EditEstateState();
}

class _EditEstateState extends State<EditEstate> {
  final AddEstateServices backendService = AddEstateServices();
  String? _layoutId;
  AutoCadLayout? _pendingLayout;
  final ImagePicker imgpicker = ImagePicker();
  late LatLng _editedLocation;
  List<XFile>? imagefiles;
  List<XFile> newImageFiles = [];
  List<String> existingImageUrls = [];
  final ImagePicker imgPicker = ImagePicker();
  final FirebaseStorage storage = FirebaseStorage.instance;
  // --- add with other fields ---
  late final String _origNameAr;
  late final String _origNameEn;
  bool _setUnderProcess = false; // flip to true when user confirms name change

  // Text Controllers
  final TextEditingController arNameController = TextEditingController();
  final TextEditingController arEstateBranchController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController enEstateBranchController =
      TextEditingController();
  final TextEditingController arBioController = TextEditingController();
  final TextEditingController enNameController = TextEditingController();
  final TextEditingController enBioController = TextEditingController();
  TextEditingController menuLinkController = TextEditingController();

  // Location Controllers
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  // Rooms
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

  // Room availability
  bool single = false;
  bool doubleRoom = false;
  bool suite = false;
  bool family = false;

  // Location values
  String? countryValue;
  String? stateValue;
  String? cityValue;

  // Firebase
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref("App").child("Estate");

  // Selections
  List<String> selectedRestaurantTypes = [];
  List<String> selectedEntries = [];
  List<String> selectedEditSessionsType = [];
  List<String> selectedEditAdditionalsType = [];
  List<String> lstMusicCoffee = [];
  final _formKey = GlobalKey<FormState>();

  // Toggles
  bool isMusicSelected = false;
  bool hasKidsArea = false;
  bool hasSwimmingPoolSelected = false;
  bool hasJacuzziSelected = false;
  bool hasBarberSelected = false;
  bool hasMassageSelected = false;
  bool hasGymSelected = false;
  bool isSmokingAllowed = false;
  bool hasValet = false;
  bool valetWithFees = false;

  // METRO: controller + cached original (to detect changes)
  final MetroSelectionController _metro = MetroSelectionController();
  String _metroCity = ""; // "Riyadh" or ""
  Map<String, List<String>> _metroPrevStationsByLine = {};
  List<String> _metroPrevLines = [];

  @override
  void initState() {
    super.initState();

    _origNameAr = (widget.objEstate["NameAr"] ?? '').toString();
    _origNameEn = (widget.objEstate["NameEn"] ?? '').toString();

    // METRO: hydrate controller from existing DB object
    final metro = widget.objEstate["Metro"];
    if (metro is Map) {
      _metroCity = (metro["City"] ?? "").toString();
      final lines = metro["Lines"];
      if (lines is Map) {
        _metroPrevStationsByLine = {};
        _metroPrevLines = [];
        lines.forEach((lineName, value) {
          final ln = lineName.toString();
          final stationsStr =
              (value is Map ? value["Stations"] : "")?.toString() ?? "";
          final stations = stationsStr
              .split(",")
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          _metroPrevLines.add(ln);
          _metroPrevStationsByLine[ln] = stations;

          // Hydrate controller (guard list)
          // Hydrate controller (guard set)
          _metro.selectedLines[ln] = true;
          final set =
              _metro.selectedStationsByLine.putIfAbsent(ln, () => <String>{});
          set.addAll(
              stations); // stations is List<String>; addAll works on Set<String>
        });
      }
    }

    if (widget.objEstate.containsKey('LayoutId')) {
      _layoutId = widget.objEstate['LayoutId'];
    }

    final double lat =
        double.tryParse(widget.objEstate["Lat"].toString()) ?? 37.7749;
    final double lon =
        double.tryParse(widget.objEstate["Lon"].toString()) ?? -122.4194;
    _editedLocation = LatLng(lat, lon);

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
    arEstateBranchController.text = widget.objEstate["BranchAr"] ?? '';
    enEstateBranchController.text = widget.objEstate["BranchEn"] ?? '';
    phoneNumberController.text = widget.objEstate["EstatePhoneNumber"] ?? '';

    if (widget.objEstate.containsKey('TypeofRestaurant')) {
      String typeOfRestaurant = widget.objEstate['TypeofRestaurant'];
      selectedRestaurantTypes = typeOfRestaurant
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (widget.objEstate.containsKey('Entry')) {
      String entry = widget.objEstate['Entry'];
      selectedEntries = entry
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

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

    if (widget.objEstate.containsKey('Lstmusic')) {
      String entry = widget.objEstate['Lstmusic'];
      lstMusicCoffee = entry
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    hasKidsArea = widget.objEstate["HasKidsArea"] == "1";
    hasSwimmingPoolSelected = widget.objEstate["HasSwimmingPool"] == "1";
    hasBarberSelected = widget.objEstate["HasBarber"] == "1";
    hasGymSelected = widget.objEstate["HasGym"] == "1";
    hasJacuzziSelected = widget.objEstate["HasJacuzziInRoom"] == "1";
    hasMassageSelected = widget.objEstate["HasMassage"] == "1";
    isSmokingAllowed = widget.objEstate["IsSmokingAllowed"] == "1";
    hasValet = widget.objEstate["HasValet"] == "1";
    valetWithFees = widget.objEstate["ValetWithFees"] == "1";

    // Rooms
    for (var room in widget.LstRooms) {
      switch (room.name.toLowerCase()) {
        case "single":
          single = true;
          singleController.text = room.price;
          arBioSingleController.text = room.bio;
          enBioSingleController.text = room.bioEn;
          singleControllerID.text = room.id;
          break;
        case "double":
          doubleRoom = true;
          doubleController.text = room.price;
          arBioDoubleController.text = room.bio;
          enBioDoubleController.text = room.bioEn;
          doubleControllerID.text = room.id;
          break;
        case "suite":
          suite = true;
          suiteController.text = room.price;
          arBioSuiteController.text = room.bio;
          enBioSuiteController.text = room.bioEn;
          suiteControllerID.text = room.id;
          break;
        case "family":
          family = true;
          familyController.text = room.price;
          arBioFamilyController.text = room.bio;
          enBioFamilyController.text = room.bioEn;
          familyControllerID.text = room.id;
          break;
        default:
          break;
      }
    }
  }

  Future<Map<String, String>> _reverseGeocode(LatLng p) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );

      if (placemarks.isEmpty) return {};

      final pm = placemarks.first;

      final city = (pm.locality ?? pm.subAdministrativeArea ?? "").trim();
      final state = (pm.administrativeArea ?? "").trim();
      final country = (pm.country ?? "").trim();

      // ✅ Branch suggestion (neighborhood/area)
      final branch =
          (pm.subLocality ?? pm.subAdministrativeArea ?? pm.locality ?? "")
              .trim();

      final out = <String, String>{};
      if (country.isNotEmpty) out["Country"] = country;
      if (state.isNotEmpty) out["State"] = state;
      if (city.isNotEmpty) out["City"] = city;
      if (branch.isNotEmpty) out["Branch"] = branch;

      debugPrint("✅ Reverse result => $out");
      return out;
    } catch (e) {
      debugPrint("❌ Reverse geocode error: $e");
      return {};
    }
  }

  Future<void> _fetchEstateImages() async {
    try {
      String typePath = widget.estateType == "1"
          ? "Hottel"
          : (widget.estateType == "2" ? "Coffee" : "Restaurant");
      final snap = await FirebaseDatabase.instance
          .ref('App/Estate/$typePath/${widget.estateId}/ImageUrls')
          .get();

      if (snap.exists && snap.value != null) {
        final raw = snap.value as List<dynamic>;
        setState(() {
          existingImageUrls = raw.map((e) => e.toString()).toList();
        });
        return;
      }
    } catch (e) {
      debugPrint("failed to read ImageUrls from DB: $e");
    }

    try {
      final result = await storage.ref(widget.estateId).listAll();
      final urls = <String>[];
      for (var item in result.items) {
        urls.add(await item.getDownloadURL());
      }
      setState(() {
        existingImageUrls = List<String>.from(urls);
      });
    } catch (e) {
      debugPrint("Error fetching images from Storage: $e");
    }
  }

  bool _hasPartialMetroSelection() {
    // True if at least one line is selected but stations are missing for it
    return _metro.selectedLines.entries.any(
      (entry) =>
          entry.value &&
          (_metro.selectedStationsByLine[entry.key]?.isEmpty ?? true),
    );
  }

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

  DatabaseReference _imageUrlsRef() {
    final String typePath = widget.estateType == "1"
        ? "Hottel"
        : (widget.estateType == "2" ? "Coffee" : "Restaurant");
    return FirebaseDatabase.instance
        .ref('App/Estate/$typePath/${widget.estateId}/ImageUrls');
  }

  Future<void> removeImage(String imageUrl) async {
    try {
      if (existingImageUrls.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  getTranslated(context, "At least one image is required."))),
        );
        return;
      }
      await storage.refFromURL(imageUrl).delete();
      setState(() {
        existingImageUrls.remove(imageUrl);
      });
      await _imageUrlsRef().set(existingImageUrls);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(getTranslated(context, "Image removed successfully"))),
      );
    } catch (e) {
      debugPrint("Error removing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(context, "Failed to remove image"))),
      );
    }
  }

  Future<void> saveUpdatedImages() async {
    if (newImageFiles.isEmpty) return;

    final totalNew = newImageFiles.length;
    final progressNotifier = ValueNotifier<double>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, pct, _) {
              final display = (pct * 100).clamp(0, 100).toStringAsFixed(0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${getTranslated(context, "DoNotCloseApp")}: $display%'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: pct),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      final existingNames = await fetchExistingImages();
      int maxIdx = -1;
      for (var name in existingNames) {
        final idx = int.tryParse(name.split('.').first) ?? -1;
        if (idx > maxIdx) maxIdx = idx;
      }
      int nextIndex = maxIdx + 1;

      final List<String> uploadedUrls = [];

      for (var i = 0; i < newImageFiles.length; i++) {
        final file = File(newImageFiles[i].path);
        final fileName = '$nextIndex.jpg';
        final ref = storage.ref(widget.estateId).child(fileName);
        final task = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes != 0) {
            final filePct = snap.bytesTransferred / snap.totalBytes!;
            progressNotifier.value = (i + filePct) / totalNew;
          }
        });

        final snap = await task;
        final url = await snap.ref.getDownloadURL();
        uploadedUrls.add(url);
        nextIndex++;
      }

      setState(() {
        existingImageUrls.addAll(uploadedUrls);
        newImageFiles.clear();
      });

      await _imageUrlsRef().set(existingImageUrls);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(getTranslated(context, "Images updated successfully"))),
      );
    } catch (e) {
      debugPrint("Error saving updated images: $e");
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(context, "Failed to update images"))),
      );
    }
  }

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
      existingImages.sort((a, b) {
        int numA = int.tryParse(a.split('.').first) ?? 0;
        int numB = int.tryParse(b.split('.').first) ?? 0;
        return numA.compareTo(numB);
      });
      return existingImages;
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }

  Future<File> compressImage(File image) async {
    final result = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 800,
      minHeight: 600,
      quality: 80,
    );
    final compressedFile = File(image.path)..writeAsBytesSync(result!);
    return compressedFile;
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
                Navigator.of(context).pop();
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

      await dbRef.child("App/EstateChats/$estateId").remove();

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
    if (widget.estateType == "3") {
      if (selectedRestaurantTypes.isEmpty ||
          selectedEntries.isEmpty ||
          selectedEditSessionsType.isEmpty) {
        return false;
      }
    } else if (widget.estateType == "2") {
      if (selectedEntries.isEmpty || selectedEditSessionsType.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String estateType = widget.objEstate['Type'] ?? "1";
    bool isLoading = existingImageUrls.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    SizedBox(height: 25),
                    TextHeader("Edit Estate Images"),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: pickImages,
                            icon: const Icon(Icons.add_a_photo,
                                color: kPurpleColor, size: 28),
                            tooltip: getTranslated(context, "Add New Images"),
                            splashColor: kPurpleColor.withOpacity(0.2),
                            highlightColor: kPurpleColor.withOpacity(0.2),
                          ),
                          TextHeader("Add New Images"),
                        ],
                      ),
                    ),

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
                              Icon(Icons.image, color: kPurpleColor, size: 80),
                              const SizedBox(height: 20),
                              Text(
                                getTranslated(context, "Loading images..."),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),
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

                    10.kH,
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

                    TextHeader("Information in Arabic"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormFieldStyle(
                        context: context,
                        hint: getTranslated(context, "Name"),
                        icon: const Icon(Icons.person, color: kPurpleColor),
                        control: arNameController,
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
                        icon: const Icon(Icons.info, color: kPurpleColor),
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
                        icon: const Icon(Icons.person, color: kPurpleColor),
                        control: enNameController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.text,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormFieldStyle(
                        context: context,
                        hint: "Bio",
                        icon: const Icon(Icons.info, color: kPurpleColor),
                        control: enBioController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.multiline,
                      ),
                    ),

                    // 40.kH,
                    // TextHeader("Branch in Arabic"),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: TextFormFieldStyle(
                    //     context: context,
                    //     hint: "Branch in Arabic",
                    //     icon: const Icon(Icons.person, color: kPurpleColor),
                    //     control: arEstateBranchController,
                    //     isObsecured: false,
                    //     validate: true,
                    //     textInputType: TextInputType.text,
                    //     validator: (value) {
                    //       if (value == null || value.trim().isEmpty) {
                    //         return getTranslated(context,
                    //             "Estate's branch name in arabic is missing");
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    // ),
                    //
                    // // METRO: header + summary + picker (visible only when City == Riyadh)
                    //
                    // 40.kH,
                    // TextHeader("Branch in English"),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: TextFormFieldStyle(
                    //     context: context,
                    //     hint: "Branch in English",
                    //     icon: const Icon(Icons.person, color: kPurpleColor),
                    //     control: enEstateBranchController,
                    //     isObsecured: false,
                    //     validate: true,
                    //     textInputType: TextInputType.text,
                    //     validator: (value) {
                    //       if (value == null || value.trim().isEmpty) {
                    //         return getTranslated(context,
                    //             "Estate's branch name in english is missing");
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    // ),

                    SizedBox(height: 40),
                    if (estateType == "2" || estateType == "3") ...[
                      20.kH,
                      TextHeader("Floor Plan (Optional)"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.map, color: kPurpleColor),
                              label: Text(_layoutId == null
                                  ? getTranslated(
                                      context, "Configure Floor Plan")
                                  : getTranslated(
                                      context, "Reconfigure Floor Plan")),
                              onPressed: () async {
                                final layout =
                                    await Navigator.push<AutoCadLayout?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeatMapBuilderScreen(
                                      childType: estateType == "2"
                                          ? "Coffee"
                                          : "Restaurant",
                                      estateId: widget.estateId,
                                      initialLayoutId: _layoutId,
                                    ),
                                  ),
                                );
                                if (layout != null) {
                                  setState(() {
                                    _layoutId = layout.layoutId;
                                    _pendingLayout = layout;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        getTranslated(
                                            context, "Floor plan ready"),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (_layoutId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${getTranslated(context, 'Configured Layout ID:')} $_layoutId",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    40.kH,
                    TextHeader("Menu"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormFieldStyle(
                        context: context,
                        hint: "Enter Menu Link",
                        icon: const Icon(Icons.person, color: kPurpleColor),
                        control: menuLinkController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.text,
                      ),
                    ),

                    40.kH,
                    TextHeader("Phone Number"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormFieldStyle(
                        context: context,
                        hint: "Phone Number",
                        icon: const Icon(Icons.phone_android_outlined,
                            color: kPurpleColor),
                        control: phoneNumberController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.text,
                      ),
                    ),

                    SizedBox(height: 20),
                    TextHeader("Edit Estate Location"),
                    // EditLocationSection(
                    //   initialLocation: _editedLocation,
                    //   onLocationChanged: (newLocation) {
                    //     setState(() {
                    //       _editedLocation = newLocation;
                    //     });
                    //   },
                    // ),
                    EditLocationSection(
                        initialLocation: _editedLocation,
                        onLocationChanged: (newLocation) async {
                          // 1) Update Lat/Lon
                          setState(() {
                            _editedLocation = newLocation;
                          });

                          // 2) Reverse geocode
                          final ccs = await _reverseGeocode(newLocation);
                          if (!mounted) return;

                          if (ccs.isNotEmpty) {
                            setState(() {
                              countryValue = ccs["Country"] ?? countryValue;
                              stateValue = ccs["State"] ?? stateValue;
                              cityValue = ccs["City"] ?? cityValue;

                              countryController.text = countryValue ?? "";
                              stateController.text = stateValue ?? "";
                              cityController.text = cityValue ?? "";

                              // ✅ ALWAYS update branch
                              final branch = (ccs["Branch"] ?? "").trim();
                              if (branch.isNotEmpty) {
                                enEstateBranchController.text = branch;
                                arEstateBranchController.text = branch;
                              }

                              // ✅ Metro reset if leaving Riyadh
                              final isRiyadhNow =
                                  (cityValue ?? "").toLowerCase().trim() ==
                                      "riyadh";

                              if (!isRiyadhNow) {
                                _metro.selectedLines.clear();
                                _metro.selectedStationsByLine.clear();
                                _metroCity = "";
                              } else {
                                _metroCity = "Riyadh";
                              }
                            });

                            debugPrint(
                                "✅ Location + Country/State/City/Branch updated from map");
                          }
                        }

                        // onLocationChanged: (newLocation) async {
                        //   // 1) Update Lat/Lon
                        //   setState(() {
                        //     _editedLocation = newLocation;
                        //   });
                        //
                        //   // 2) Reverse geocode -> update Country/State/City like MapsScreen
                        //   final ccs = await _reverseGeocode(newLocation);
                        //
                        //   if (!mounted) return;
                        //
                        //   if (ccs.isNotEmpty) {
                        //     setState(() {
                        //       countryValue = ccs["Country"] ?? countryValue;
                        //       stateValue = ccs["State"] ?? stateValue;
                        //       cityValue = ccs["City"] ?? cityValue;
                        //
                        //       countryController.text =
                        //           countryValue?.toString() ?? "";
                        //       stateController.text = stateValue?.toString() ?? "";
                        //       cityController.text = cityValue?.toString() ?? "";
                        //
                        //       // ✅ Auto-Branch suggestion (only if branch fields are empty OR you want to always overwrite)
                        //       // final branch = (ccs["Branch"] ?? "").trim();
                        //       // if (branch.isNotEmpty) {
                        //       //   if (enEstateBranchController.text
                        //       //       .trim()
                        //       //       .isEmpty) {
                        //       //     enEstateBranchController.text = branch;
                        //       //   }
                        //       //   if (arEstateBranchController.text
                        //       //       .trim()
                        //       //       .isEmpty) {
                        //       //     arEstateBranchController.text =
                        //       //         branch; // optional: keep same text if you don't translate
                        //       //   }
                        //       // }
                        //       // ✅ ALWAYS update branch from map location
                        //       final branch = (ccs["Branch"] ?? "").trim();
                        //
                        //       if (branch.isNotEmpty) {
                        //         enEstateBranchController.text = branch;
                        //         arEstateBranchController.text = branch;
                        //       }
                        //
                        //       // Metro reset if leaving Riyadh
                        //       final isRiyadhNow = (cityValue ?? "")
                        //               .toString()
                        //               .toLowerCase()
                        //               .trim() ==
                        //           "riyadh";
                        //       if (!isRiyadhNow) {
                        //         _metro.selectedLines.clear();
                        //         _metro.selectedStationsByLine.clear();
                        //         _metroCity = "";
                        //       } else {
                        //         _metroCity = "Riyadh";
                        //       }
                        //     });
                        //
                        //     debugPrint(
                        //         "✅ Location + Country/City/State (+Branch) updated after map change.");
                        //   } else {
                        //     debugPrint(
                        //         "⚠️ Reverse returned empty; Country/City/State not changed.");
                        //   }
                        // },
                        ),

                    // 40.kH,
                    // TextHeader("Location information"),
                    // const SizedBox(height: 20),
                    // ChooseCity(),
                    40.kH,
                    // TextHeader("Nearby Riyadh Metro (Optional)"),

                    // Summary of current choices
                    if ((_metroCity.toLowerCase() == "riyadh") ||
                        (cityValue?.toLowerCase() == "riyadh"))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Builder(
                          builder: (_) {
                            final chosenLines =
                                _metro.chosenLinesLocalized(context);
                            final totalStations =
                                _metro.chosenStationsByLine.values.fold<int>(
                                    0,
                                    (p, v) =>
                                        p + ((v is Iterable) ? v.length : 0));

                            return Row(
                              children: [
                                const Icon(
                                    Icons.directions_subway_filled_rounded,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chosenLines.isEmpty
                                        ? getTranslated(
                                            context, "No metro lines selected.")
                                        : getTranslated(
                                                context, "Selected Lines: ") +
                                            chosenLines.join(" • ") +
                                            "  —  " +
                                            getTranslated(
                                                context, "Stations: ") +
                                            "$totalStations",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    if ((_metroCity.toLowerCase() == "riyadh") ||
                        (cityValue?.toLowerCase() == "riyadh"))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RiyadhMetroPicker(
                          controller: _metro,
                          isVisible: true,
                          onChanged: () => setState(() {}),
                        ),
                      ),

                    if ((_metroCity.toLowerCase() == "riyadh") ||
                        (cityValue?.toLowerCase() == "riyadh")) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Builder(
                          builder: (_) {
                            // ✅ Look at the raw controller state (lines + sets)
                            final hasLineNoStations =
                                _metro.selectedLines.entries.any(
                              (e) =>
                                  e.value &&
                                  (_metro.selectedStationsByLine[e.key]
                                          ?.isEmpty ??
                                      true),
                            );

                            if (!hasLineNoStations)
                              return const SizedBox.shrink();

                            return Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 18, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    getTranslated(context,
                                        "You selected a metro line but no stations."),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    Visibility(
                        visible: estateType != "3",
                        child: const SizedBox(height: 40)),

                    if (estateType == "2" || estateType == "3")
                      EditEntryVisibility(
                        isVisible: true,
                        initialSelectedEntries: selectedEntries,
                        onCheckboxChanged: (bool isChecked, String label) {
                          setState(() {
                            if (isChecked) {
                              if (!selectedEntries.contains(label)) {
                                selectedEntries.add(label);
                              }
                            } else {
                              selectedEntries.remove(label);
                            }
                          });
                        },
                      ),
                    if (estateType == "2" || estateType == "3")
                      EditSessionsType(
                        isVisible: true,
                        initialSelectedEntries: selectedEditSessionsType,
                        onCheckboxChanged: (bool isChecked, String label) {
                          setState(() {
                            if (isChecked) {
                              if (!selectedEditSessionsType.contains(label)) {
                                selectedEditSessionsType.add(label);
                              }
                            } else {
                              selectedEditSessionsType.remove(label);
                            }
                          });
                        },
                      ),
                    if (estateType == "2" || estateType == "3")
                      EditAdditionals(
                        isVisible: true,
                        initialSelectedEntries: selectedEditAdditionalsType,
                        onCheckboxChanged: (bool isChecked, String label) {
                          setState(() {
                            if (isChecked) {
                              if (!selectedEditAdditionalsType
                                  .contains(label)) {
                                selectedEditAdditionalsType.add(label);
                              }
                            } else {
                              selectedEditAdditionalsType.remove(label);
                            }
                          });
                        },
                      ),

                    if (estateType == "2") ...[
                      EditCoffeeMusicServices(
                        isVisible: true,
                        initialSelectedEntries: isMusicSelected
                            ? (lstMusicCoffee.isNotEmpty
                                ? ["Is there music", ...lstMusicCoffee]
                                : [])
                            : [],
                        onCheckboxChanged: (bool isChecked, String label) {
                          setState(() {
                            if (label == "Is there music") {
                              isMusicSelected = isChecked;
                              if (!isChecked) lstMusicCoffee.clear();
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
                      EditMusicServices(
                        isVisible: true,
                        allowAdditionalOptions: false,
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

                    if (estateType == "3") const SizedBox(height: 40),
                    if (estateType == "3")
                      EditRestaurantTypeVisibility(
                        isVisible: true,
                        initialSelectedTypes: selectedRestaurantTypes,
                        onCheckboxChanged: (bool isChecked, String label) {
                          setState(() {
                            if (isChecked) {
                              if (!selectedRestaurantTypes.contains(label)) {
                                selectedRestaurantTypes.add(label);
                              }
                            } else {
                              selectedRestaurantTypes.remove(label);
                            }
                          });
                        },
                      ),

                    const SizedBox(height: 40),

                    EditKidsArea(
                      isVisible: true,
                      hasKidsArea: hasKidsArea,
                      onCheckboxChanged: (bool isChecked) {
                        setState(() {
                          hasKidsArea = isChecked;
                        });
                      },
                    ),
                    20.kH,
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
                          TextHeader("Smoking Area?"),
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

                    const SizedBox(height: 40),
                    Column(
                      children: [
                        TextHeader("Valet Options"),
                        EditValetOptions(
                          isVisible: true,
                          hasValet: hasValet,
                          valetWithFees: valetWithFees,
                          onCheckboxChanged: (bool isChecked) {
                            setState(() {
                              hasValet = isChecked;
                              if (!hasValet) valetWithFees = false;
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
                    Visibility(
                      visible: estateType == "1",
                      child: Column(
                        children: [
                          TextHeader(getTranslated(context, "What We have ?")),
                          // Single
                          Visibility(
                            visible: !single,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, "Single"),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  Checkbox(
                                    checkColor: Colors.white,
                                    value: single,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        single = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Single details
                          Visibility(
                            visible: single,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextHeader(
                                            getTranslated(context, "Single")),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Price"),
                                          icon: const Icon(Icons.attach_money,
                                              color: kPurpleColor),
                                          control: singleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.number,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Bio"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: arBioSingleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "BioEn"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: enBioSingleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: closeTextFormFieldStyle(() {
                                    setState(() {
                                      single = false;
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ),

                          // Double
                          Visibility(
                            visible: !doubleRoom,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, "Double"),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  Checkbox(
                                    checkColor: Colors.white,
                                    value: doubleRoom,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        doubleRoom = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: doubleRoom,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextHeader(
                                            getTranslated(context, "Double")),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Price"),
                                          icon: const Icon(Icons.attach_money,
                                              color: kPurpleColor),
                                          control: doubleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.number,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Bio"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: arBioDoubleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "BioEn"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: enBioDoubleController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: closeTextFormFieldStyle(() {
                                    setState(() {
                                      doubleRoom = false;
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ),

                          // Suite
                          Visibility(
                            visible: !suite,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, "Suite"),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  Checkbox(
                                    checkColor: Colors.white,
                                    value: suite,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        suite = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: suite,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextHeader(
                                            getTranslated(context, "Suite")),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Price"),
                                          icon: const Icon(Icons.attach_money,
                                              color: kPurpleColor),
                                          control: suiteController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.number,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Bio"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: arBioSuiteController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "BioEn"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: enBioSuiteController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: closeTextFormFieldStyle(() {
                                    setState(() {
                                      suite = false;
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ),

                          // Family
                          Visibility(
                            visible: !family,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, "Family"),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  Checkbox(
                                    checkColor: Colors.white,
                                    value: family,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        family = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: family,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextHeader(
                                            getTranslated(context, "Family")),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Price"),
                                          icon: const Icon(Icons.attach_money,
                                              color: kPurpleColor),
                                          control: familyController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.number,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "Bio"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: arBioFamilyController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                        TextFormFieldStyle(
                                          context: context,
                                          hint: getTranslated(context, "BioEn"),
                                          icon: const Icon(Icons.info,
                                              color: kPurpleColor),
                                          control: enBioFamilyController,
                                          isObsecured: false,
                                          validate: true,
                                          textInputType: TextInputType.text,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: closeTextFormFieldStyle(() {
                                    setState(() {
                                      family = false;
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
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
                        // 1) Validate required selections and form
                        final bool isEntryValid = validateSelection();
                        if (!isEntryValid) {
                          showDialog(
                            context: context,
                            builder: (_) => const FailureDialog(
                              text: "Incomplete Entry",
                              text1: "Select at least 1!",
                            ),
                          );
                          return;
                        }
                        if (!_formKey.currentState!.validate()) return;

                        // 2) Metro completeness check (Riyadh only)
                        final String nowCity =
                            ((cityValue ?? widget.objEstate["City"]) ?? "")
                                .toString()
                                .trim();
                        final String wasCity =
                            ((widget.objEstate["City"]) ?? "")
                                .toString()
                                .trim();
                        final bool cityIsRiyadhNow =
                            nowCity.toLowerCase() == "riyadh";
                        final bool cityWasRiyadh =
                            wasCity.toLowerCase() == "riyadh";

                        final List<String> selectedLines = _metro.chosenLines;
                        final bool hasPartialMetroSelection =
                            _metro.selectedLines.entries.any(
                          (e) =>
                              e.value &&
                              (_metro.selectedStationsByLine[e.key]?.isEmpty ??
                                  true),
                        );

                        if (cityIsRiyadhNow &&
                            selectedLines.isNotEmpty &&
                            hasPartialMetroSelection) {
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(getTranslated(
                                  context, "Metro selection incomplete")),
                              content: Text(
                                getTranslated(context,
                                        "You selected at least one metro line but did not choose any station on it.") +
                                    "\n\n" +
                                    getTranslated(context,
                                        "Do you want to continue without saving any Metro info?"),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(getTranslated(
                                      context, "Choose stations")),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child:
                                      Text(getTranslated(context, "Continue")),
                                ),
                              ],
                            ),
                          );
                          if (proceed != true) return; // let user fix
                          // user chose to continue: clear metro so it's not saved
                          _metro.selectedLines.clear();
                          _metro.selectedStationsByLine.clear();
                        }

                        // 3) Detect changes (excluding Metro handled above)
                        String estateType = widget.objEstate['Type'] ?? "1";
                        bool otherChanges = false;

                        // Field changes
                        if (arEstateBranchController.text !=
                                (widget.objEstate["BranchAr"] ?? '') ||
                            phoneNumberController.text !=
                                (widget.objEstate["EstatePhoneNumber"] ?? '') ||
                            enEstateBranchController.text !=
                                (widget.objEstate["BranchEn"] ?? '') ||
                            arBioController.text !=
                                (widget.objEstate["BioAr"] ?? '') ||
                            enBioController.text !=
                                (widget.objEstate["BioEn"] ?? '') ||
                            menuLinkController.text !=
                                (widget.objEstate["MenuLink"] ?? '') ||
                            countryValue !=
                                (widget.objEstate["Country"] ?? '') ||
                            cityValue != (widget.objEstate["City"] ?? '') ||
                            stateValue != (widget.objEstate["State"] ?? '') ||
                            _editedLocation.latitude !=
                                double.tryParse(
                                    widget.objEstate["Lat"].toString()) ||
                            _editedLocation.longitude !=
                                double.tryParse(
                                    widget.objEstate["Lon"].toString())) {
                          otherChanges = true;
                        }

                        // Toggles & lists
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
                            (((isMusicSelected ? "1" : "0") !=
                                (widget.objEstate["Music"] ?? "0"))) ||
                            (lstMusicCoffee.join(",") !=
                                (widget.objEstate["Lstmusic"] ?? '')) ||
                            (((hasKidsArea ? "1" : "0") !=
                                (widget.objEstate["HasKidsArea"] ?? "0"))) ||
                            (((hasSwimmingPoolSelected ? "1" : "0") !=
                                (widget.objEstate["HasSwimmingPool"] ??
                                    "0"))) ||
                            (((hasBarberSelected ? "1" : "0") !=
                                (widget.objEstate["HasBarber"] ?? "0"))) ||
                            (((hasGymSelected ? "1" : "0") !=
                                (widget.objEstate["HasGym"] ?? "0"))) ||
                            (((hasJacuzziSelected ? "1" : "0") !=
                                (widget.objEstate["HasJacuzziInRoom"] ??
                                    "0"))) ||
                            (((hasMassageSelected ? "1" : "0") !=
                                (widget.objEstate["HasMassage"] ?? "0"))) ||
                            (((isSmokingAllowed ? "1" : "0") !=
                                (widget.objEstate["IsSmokingAllowed"] ??
                                    "0"))) ||
                            (((hasValet ? "1" : "0") !=
                                (widget.objEstate["HasValet"] ?? "0"))) ||
                            (((valetWithFees ? "1" : "0") !=
                                (widget.objEstate["ValetWithFees"] ?? "0")))) {
                          otherChanges = true;
                        }

                        // Media/Layout
                        if (newImageFiles.isNotEmpty) otherChanges = true;
                        if (_pendingLayout != null) otherChanges = true;

                        // Metro changed?
                        bool metroChanged = false;
                        if (cityIsRiyadhNow && cityWasRiyadh) {
                          final nowLines = List<String>.from(_metro.chosenLines)
                            ..sort();
                          final prevLines = List<String>.from(_metroPrevLines)
                            ..sort();
                          const eq = ListEquality<String>();
                          if (nowLines.length != prevLines.length ||
                              !eq.equals(nowLines, prevLines)) {
                            metroChanged = true;
                          } else {
                            for (final ln in nowLines) {
                              final prev = List<String>.from(
                                  _metroPrevStationsByLine[ln] ??
                                      const <String>[])
                                ..sort();
                              final now = List<String>.from(
                                  _metro.chosenStationsByLine[ln] ??
                                      const <String>[])
                                ..sort();
                              if (now.length != prev.length ||
                                  !eq.equals(now, prev)) {
                                metroChanged = true;
                                break;
                              }
                            }
                          }
                        } else if (cityIsRiyadhNow != cityWasRiyadh) {
                          metroChanged = true;
                        }
                        if (metroChanged) otherChanges = true;

                        // 4) Name change (Arabic or English)
                        final String origAr = _origNameAr.trim();
                        final String origEn = _origNameEn.trim();
                        final String newAr = arNameController.text.trim();
                        final String newEn = enNameController.text.trim();
                        final bool nameChanged =
                            (newAr != origAr) || (newEn != origEn);

                        bool willSetUnderProcess = false;

                        if (nameChanged) {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(getTranslated(
                                  context, "Change estate name?")),
                              content: Text(
                                getTranslated(context,
                                    "Are you sure you want to change the estate name? If you proceed, your estate will go under process for review by our call center."),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(getTranslated(context, "Cancel")),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(
                                      getTranslated(context, "Yes, continue")),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) {
                            // User cancelled: revert names to originals and DO NOT save them
                            arNameController.text = origAr;
                            enNameController.text = origEn;

                            // If there are NO other changes at all, show "No changes" and exit
                            if (!otherChanges) {
                              await showDialog(
                                context: context,
                                builder: (_) => const FailureDialog(
                                  text: "No Changes Detected",
                                  text1:
                                      "You did not make any changes to your estate.",
                                ),
                              );
                              return;
                            }
                            // else continue with saving only non-name changes
                          } else {
                            // Confirmed -> mark under process; proceed with save incl. new names
                            willSetUnderProcess = true;
                          }
                        } else {
                          // no name change; if nothing else changed, stop with "No changes"
                          if (!otherChanges) {
                            await showDialog(
                              context: context,
                              builder: (_) => const FailureDialog(
                                text: "No Changes Detected",
                                text1:
                                    "You did not make any changes to your estate.",
                              ),
                            );
                            return;
                          }
                        }

                        // 5) Single UPDATE call (includes Metro + fields)
                        await Update(setUnderProcess: willSetUnderProcess);

                        // 6) Media & layout
                        if (newImageFiles.isNotEmpty) {
                          await saveUpdatedImages();
                        }
                        if (_pendingLayout != null) {
                          final childType =
                              (estateType == "2") ? "Coffee" : "Restaurant";
                          await backendService.uploadAutoCadLayout(
                            childType: childType,
                            estateId: widget.estateId,
                            layout: _pendingLayout!,
                          );
                          _pendingLayout = null;
                        }

                        // 7) Post-save dialogs
                        if (willSetUnderProcess) {
                          await showDialog(
                            context: context,
                            builder: (_) => const UnderProcessDialog(
                              text: 'Processing',
                              text1: 'Your request is under process.',
                            ),
                          );
                        } else {
                          await showDialog(
                            context: context,
                            builder: (_) => const SuccessDialog(
                              text: "Success",
                              text1:
                                  "Your estate has been successfully updated.",
                            ),
                          );
                        }

                        // 8) Update in-memory originals to avoid re-prompt next time
                        _origNameAr = arNameController.text;
                        _origNameEn = enNameController.text;

                        // 9) Navigate back for Coffee/Restaurant
                        if (estateType == "2" || estateType == "3") {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Update estate information in Firebase (includes Metro)
  /// Update estate information in Firebase (includes Metro)
  Future<void> Update({bool setUnderProcess = false}) async {
    String ChildType;
    String type;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String estateType = widget.objEstate['Type'] ?? "1";

    // ===== METRO: write/remove Metro node =====
    final String effectiveCity = (cityValue ?? _metroCity ?? "").toString();
    final bool isRiyadh = effectiveCity.toLowerCase() == "riyadh";
    final chosenLines = _metro.chosenLines; // List<String>
    final chosenStationsByLine =
        _metro.chosenStationsByLine; // Map<String, Set<String>>

    final String childTypePath = (estateType == "1")
        ? "Hottel"
        : (estateType == "2")
            ? "Coffee"
            : "Restaurant";

    final DatabaseReference estateRef =
        ref.child(childTypePath).child(widget.objEstate['IDEstate'].toString());

    if (!isRiyadh || chosenLines.isEmpty) {
      await estateRef.child("Metro").remove();
    } else {
      final Map<String, dynamic> linesNode = {};
      for (final ln in chosenLines) {
        final stations =
            (chosenStationsByLine[ln] ?? const <String>{}).toList();
        linesNode[ln] = {
          "Stations": stations.join(","),
        };
      }
      await estateRef.child("Metro").set({
        "City": "Riyadh",
        "Lines": linesNode,
      });
    }

    // Keep local metro snapshot aligned for next save
    _metroCity = isRiyadh ? "Riyadh" : "";
    _metroPrevLines = List<String>.from(chosenLines);
    _metroPrevStationsByLine = {};
    for (final ln in chosenLines) {
      _metroPrevStationsByLine[ln] = List<String>.from(
          (chosenStationsByLine[ln] ?? const <String>{}).toList());
    }
    // ===== END METRO =====

    if (estateType == "1") {
      ChildType = "Hottel";
      type = "1";
    } else if (estateType == "2") {
      ChildType = "Coffee";
      type = "2";
    } else {
      ChildType = "Restaurant";
      type = "3";
    }

    String? TypeAccount = sharedPreferences.getString("TypeAccount") ?? "2";
    String musicValue = isMusicSelected ? "1" : "0";

    // Build the update map
    final Map<String, dynamic> updateMap = {
      "NameAr": arNameController.text,
      "NameEn": enNameController.text,
      "BranchAr": arEstateBranchController.text,
      "BranchEn": enEstateBranchController.text,
      "EstatePhoneNumber": phoneNumberController.text,
      "BioAr": arBioController.text,
      "BioEn": enBioController.text,
      "MenuLink": menuLinkController.text,
      "Country": (countryValue ?? countryController.text).toString(),
      "City": (cityValue ?? cityController.text).toString(),
      "State": (stateValue ?? stateController.text).toString(),
      "Type": type,
      "IDUser": FirebaseAuth.instance.currentUser?.uid ?? "No Id",
      "IDEstate": widget.objEstate['IDEstate'],
      "TypeAccount": TypeAccount,
      "Music": musicValue,
      "HasKidsArea": hasKidsArea ? "1" : "0",
      "IsSmokingAllowed": isSmokingAllowed ? "1" : "0",
      "HasValet": hasValet ? "1" : "0",
      "ValetWithFees": valetWithFees ? "1" : "0",
      if (type == "1") "HasBarber": hasBarberSelected ? "1" : "0",
      if (type == "1") "HasGym": hasGymSelected ? "1" : "0",
      if (type == "1") "HasJacuzziInRoom": hasJacuzziSelected ? "1" : "0",
      if (type == "1") "HasMassage": hasMassageSelected ? "1" : "0",
      if (type == "1") "HasSwimmingPool": hasSwimmingPoolSelected ? "1" : "0",
      if (type == "3") "TypeofRestaurant": selectedRestaurantTypes.join(","),
      "Lat": _editedLocation.latitude,
      "Lon": _editedLocation.longitude,
      "Entry": selectedEntries.join(","),
      if (type == "2" || type == "3")
        "Sessions": selectedEditSessionsType.join(","),
      if (type == "2" || type == "3")
        "additionals": selectedEditAdditionalsType.join(","),
      if (type == "2") "Lstmusic": lstMusicCoffee.join(","),
      // <- Conditionally set Under Process
      if (setUnderProcess) "IsAccepted": "1",
    };

    await ref
        .child(ChildType)
        .child(widget.objEstate['IDEstate'].toString())
        .update(updateMap);

    // ===== Rooms =====
    DatabaseReference refRooms =
        FirebaseDatabase.instance.ref("App").child("Rooms");

    if (single) {
      await refRooms
          .child(widget.objEstate['IDEstate'].toString())
          .child("Single")
          .update({
        "ID": singleControllerID.text,
        "Name": "Single",
        "Price": singleController.text,
        "BioAr": arBioSingleController.text,
        "BioEn": enBioSingleController.text,
      });
    }
    if (doubleRoom) {
      await refRooms
          .child(widget.objEstate['IDEstate'].toString())
          .child("Double")
          .update({
        "ID": doubleControllerID.text,
        "Name": "Double",
        "Price": doubleController.text,
        "BioAr": arBioDoubleController.text,
        "BioEn": enBioDoubleController.text,
      });
    }
    if (suite) {
      await refRooms
          .child(widget.objEstate['IDEstate'].toString())
          .child("Suite")
          .update({
        "ID": suiteControllerID.text,
        "Name": "Suite",
        "Price": suiteController.text,
        "BioAr": arBioSuiteController.text,
        "BioEn": enBioSuiteController.text,
      });
    }
    if (family) {
      await refRooms
          .child(widget.objEstate['IDEstate'].toString())
          .child("Family")
          .set({
        "ID": familyControllerID.text,
        "Name": "Family",
        "Price": familyController.text,
        "BioAr": arBioFamilyController.text,
        "BioEn": enBioFamilyController.text,
      });
    }
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
