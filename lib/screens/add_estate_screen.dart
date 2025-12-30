// lib/screens/add_estates_screen.dart

import 'package:daimond_host_provider/backend/adding_estate_services.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import 'package:daimond_host_provider/screens/seat_map_builder_screen.dart';
import 'package:daimond_host_provider/widgets/extra_services.dart';
import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../localization/language_constants.dart';
import '../utils/additional_facility.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/rooms.dart';
import '../widgets/birthday_textform_field.dart';
import '../widgets/choose_city.dart';
import '../widgets/entry_visibility.dart';
import '../widgets/language_translator_widget.dart';
import '../widgets/music_visibility.dart';
import '../widgets/restaurant_type_visibility.dart';
import '../widgets/reused_provider_estate_container.dart';
import '../widgets/room_type_visibility.dart';
import '../widgets/sessions_visibility.dart';
import 'maps_screen.dart';
import 'package:intl/intl.dart';

// 🆕 Metro picker import
import '../widgets/riyadh_metro_picker.dart';

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddEstatesScreen extends StatefulWidget {
  final String userType;

  AddEstatesScreen({
    super.key,
    required this.userType,
  });

  @override
  State<AddEstatesScreen> createState() => _AddEstatesScreenState();
}

class _AddEstatesScreenState extends State<AddEstatesScreen> {
  final AddEstateServices backendService = AddEstateServices();
  String? _layoutId;
  AutoCadLayout? _pendingLayout;
  List<XFile>? imageFiles;

  // ===== Scroll + Anchors =====
  final ScrollController _scrollController = ScrollController();

  // Section anchors
  final GlobalKey _keyInfoAr = GlobalKey();
  final GlobalKey _keyInfoEn = GlobalKey();
  final GlobalKey _keyBranchEn = GlobalKey();
  final GlobalKey _keyBranchAr = GlobalKey();
  final GlobalKey _keyLegal = GlobalKey();
  final GlobalKey _keyFloorPlan = GlobalKey();
  final GlobalKey _keyMenu = GlobalKey();
  final GlobalKey _keyPhone = GlobalKey();
  final GlobalKey _keyFacilitiesHotel = GlobalKey();
  final GlobalKey _keyRestaurantType = GlobalKey();
  final GlobalKey _keyEntry = GlobalKey();
  final GlobalKey _keySessions = GlobalKey();
  final GlobalKey _keyMusic = GlobalKey();
  final GlobalKey _keyValet = GlobalKey();
  final GlobalKey _keyKids = GlobalKey();
  final GlobalKey _keySmoking = GlobalKey();
  final GlobalKey _keyAmenitiesHotel = GlobalKey();
  final GlobalKey _keyLocation = GlobalKey();
  final GlobalKey _keyHotelRooms = GlobalKey();
  // final GlobalKey _keyMetro = GlobalKey(); // Metro section anchor

  // Exact field anchors (scroll to field, not just header)
  final GlobalKey _keyNameArField = GlobalKey();
  final GlobalKey _keyNameEnField = GlobalKey();
  final GlobalKey _keyBranchEnField = GlobalKey();
  final GlobalKey _keyBranchArField = GlobalKey();
  // ===== Draft persistence =====
  static const String _kDraftKey = 'add_estate_draft_v1';
  Timer? _saveTimer;
  final List<TextEditingController> _textCtrls = [];
  bool _restoringDraft = false;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    }
  }

  // ===== Controllers & State =====
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController menuLinkController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  bool checkPopularRestaurants = false;
  bool checkIndianRestaurant = false;
  bool checkItalian = false;
  bool checkSeafoodRestaurant = false;
  bool checkFastFood = false;
  bool checkSteak = false;
  bool checkGrills = false;
  bool checkHealthy = false;
  bool checkMixed = false;
  bool checkFamilial = false;
  bool checkMusic = false;
  bool checkSingle = false;
  bool checkInternal = false;
  bool checkExternal = false;
  bool haveMusic = false;
  bool haveSinger = false;
  bool haveDJ = false;
  bool haveOud = false;
  bool checkIsSmokingAllowed = false;
  bool checkIsThereBreakfastLounge = false;
  bool checkIsThereLaunchLounge = false;
  bool checkIsThereDinnerLounge = false;
  TextEditingController facilityNameController = TextEditingController();
  TextEditingController facilityNameArController = TextEditingController();
  TextEditingController facilityPriceController = TextEditingController();
  List<Additional> facilityList = [];
  TextEditingController enNameController = TextEditingController();
  TextEditingController enBranchController = TextEditingController();
  TextEditingController arBranchController = TextEditingController();
  TextEditingController enBioController = TextEditingController();
  TextEditingController taxNumberController = TextEditingController();
  TextEditingController estateNumberController = TextEditingController();
  TextEditingController singleController = TextEditingController();
  TextEditingController doubleController = TextEditingController();
  TextEditingController suiteController = TextEditingController();
  TextEditingController familyController = TextEditingController();
  TextEditingController grandSuiteController = TextEditingController();
  TextEditingController grandSuiteControllerAr = TextEditingController();
  TextEditingController businessSuiteController = TextEditingController();
  TextEditingController businessSuiteControllerAr = TextEditingController();
  TextEditingController singleControllerBioAr = TextEditingController();
  TextEditingController doubleControllerBioAr = TextEditingController();
  TextEditingController suiteControllerBioAr = TextEditingController();
  TextEditingController familyControllerBioAr = TextEditingController();
  TextEditingController singleControllerBioEn = TextEditingController();
  TextEditingController doubleControllerBioEn = TextEditingController();
  TextEditingController suiteControllerBioEn = TextEditingController();
  TextEditingController familyControllerBioEn = TextEditingController();
  TextEditingController grandSuiteControllerBioEn = TextEditingController();
  TextEditingController grandSuiteControllerBioAr = TextEditingController();
  TextEditingController businessSuiteControllerBioEn = TextEditingController();
  TextEditingController businessSuiteControllerBioAr = TextEditingController();
  List<String> listTypeOfRestaurant = [];
  List<String> listEntry = [];
  // NOTE: `listSessions` intentionally not used anymore; keep or remove.
  List<String> listSessions = [];
  List<String> roomAllowance = [];
  List<String> additionals = [];
  List<String> listMusic = [];
  List<Rooms> listRooms = [];
  bool single = false;
  bool double = false;
  bool suite = false;
  bool family = false;
  bool grandSuite = false;
  bool businessSuite = false;
  // String? countryValue;
  // String? stateValue;
  // String? cityValue;
  int? idEstate;
  late Widget btnLogin;
  String breakfastPrice = '';
  String launchPrice = '';
  String dinnerPrice = '';

  // Valet
  bool hasValet = false;
  bool valetWithFees = false;

  // Kids area
  bool hasKidsArea = false;
  bool isSmokingAllowed = false;

  // Hotel amenities
  bool hasSwimmingPool = false;
  bool hasJacuzzi = false;
  bool hasBarber = false;
  bool hasMassage = false;
  bool hasGym = false;

  // Uploading states
  bool isUploadingFacility = false;
  bool isUploadingTax = false;

  // PDF URLs
  String? facilityPdfUrl;
  String? taxPdfUrl;

  // Selections
  List<String> selectedEntries = [];
  List<String> selectedSessions = [];
  List<String> selectedAdditionals = [];
  List<String> selectedRestaurantTypes = [];

  // 🆕 Metro selection controller (replaces in-file metro state/constants)
  // final MetroSelectionController _metroCtrl = MetroSelectionController();
  final TextEditingController _dateOfPhotographyController =
      TextEditingController();
  final TextEditingController _timeOfPhotographyController =
      TextEditingController();
  String? _dayOfPhotography; // computed from selected date

  // === Helpers (labels & language) ===
  bool _isArabic(BuildContext context) {
    try {
      final code = Localizations.localeOf(context).languageCode.toLowerCase();
      return code == 'ar';
    } catch (_) {
      return Directionality.of(context) == TextDirection.RTL;
    }
  }

  @override
  void dispose() {
    // Cancel any pending debounce timer
    _saveTimer?.cancel();

    // Remove listeners from all wired controllers
    for (final c in _textCtrls) {
      c.removeListener(_saveDraftDebounced);
    }

    // Dispose only the controllers you created in this screen
    _dateOfPhotographyController.dispose();
    _timeOfPhotographyController.dispose();

    super.dispose();
  }

  void _wireDraftAutosave() {
    // Register all text controllers you want autosaved
    _textCtrls.clear();
    _textCtrls.addAll([
      nameController,
      bioController,
      enNameController,
      enBioController,
      enBranchController,
      arBranchController,
      menuLinkController,
      phoneNumberController,
      taxNumberController,
      estateNumberController,
      singleController,
      doubleController,
      suiteController,
      familyController,
      grandSuiteController,
      grandSuiteControllerAr,
      businessSuiteController,
      businessSuiteControllerAr,
      singleControllerBioAr,
      doubleControllerBioAr,
      suiteControllerBioAr,
      familyControllerBioAr,
      singleControllerBioEn,
      doubleControllerBioEn,
      suiteControllerBioEn,
      familyControllerBioEn,
      grandSuiteControllerBioEn,
      grandSuiteControllerBioAr,
      businessSuiteControllerBioEn,
      businessSuiteControllerBioAr,
      _dateOfPhotographyController,
      _timeOfPhotographyController,
      facilityNameController,
      facilityNameArController,
      facilityPriceController,
    ]);

    for (final c in _textCtrls) {
      c.addListener(_saveDraftDebounced);
    }
  }

  void _saveDraftDebounced() {
    if (_restoringDraft) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _saveDraftImmediate);
  }

  Future<void> _saveDraftImmediate() async {
    if (_restoringDraft) return;
    final prefs = await SharedPreferences.getInstance();
    final map = _packDraft();
    await prefs.setString(_kDraftKey, jsonEncode(map));
  }

  Map<String, dynamic> _packDraft() {
    // NOTE: Only include serializable values (no Widgets, Keys, etc.)
    return {
      // Basic info
      'userType': widget.userType,
      'nameAr': nameController.text,
      'bioAr': bioController.text,
      'nameEn': enNameController.text,
      'bioEn': enBioController.text,
      'branchEn': enBranchController.text,
      'branchAr': arBranchController.text,

      // Legal PDFs
      'facilityPdfUrl': facilityPdfUrl ?? '',
      'taxPdfUrl': taxPdfUrl ?? '',
      'isUploadingFacility': isUploadingFacility,
      'isUploadingTax': isUploadingTax,

      // Photographer
      'dateOfPhotography': _dateOfPhotographyController.text,
      'timeOfPhotography': _timeOfPhotographyController.text,
      'dayOfPhotography': _dayOfPhotography ?? '',

      // Menu & phone
      'menuLink': menuLinkController.text,
      'estatePhone': phoneNumberController.text,

      // Location
      // 'country': countryValue,
      // 'state': stateValue,
      // 'city': cityValue,

      // Valet, Kids, Smoking
      'hasValet': hasValet,
      'valetWithFees': valetWithFees,
      'hasKidsArea': hasKidsArea,
      'isSmokingAllowed': checkIsSmokingAllowed,

      // Hotel amenities
      'hasSwimmingPool': hasSwimmingPool,
      'hasJacuzzi': hasJacuzzi,
      'hasBarber': hasBarber,
      'hasMassage': hasMassage,
      'hasGym': hasGym,

      // Hotel room toggles + prices/bios
      'single': single,
      'double': double,
      'suite': suite,
      'family': family,
      'grandSuite': grandSuite,
      'businessSuite': businessSuite,

      'singlePrice': singleController.text,
      'doublePrice': doubleController.text,
      'suitePrice': suiteController.text,
      'familyPrice': familyController.text,
      'grandSuitePrice': grandSuiteController.text,
      'grandSuitePriceAr': grandSuiteControllerAr.text,
      'businessSuitePrice': businessSuiteController.text,
      'businessSuitePriceAr': businessSuiteControllerAr.text,

      'singleBioAr': singleControllerBioAr.text,
      'doubleBioAr': doubleControllerBioAr.text,
      'suiteBioAr': suiteControllerBioAr.text,
      'familyBioAr': familyControllerBioAr.text,
      'singleBioEn': singleControllerBioEn.text,
      'doubleBioEn': doubleControllerBioEn.text,
      'suiteBioEn': suiteControllerBioEn.text,
      'familyBioEn': familyControllerBioEn.text,
      'grandSuiteBioEn': grandSuiteControllerBioEn.text,
      'grandSuiteBioAr': grandSuiteControllerBioAr.text,
      'businessSuiteBioEn': businessSuiteControllerBioEn.text,
      'businessSuiteBioAr': businessSuiteControllerBioAr.text,

      // Lounge prices (hotel)
      'breakfastPrice': breakfastPrice,
      'launchPrice': launchPrice,
      'dinnerPrice': dinnerPrice,

      // Lists (Restaurant/Coffee)
      'selectedRestaurantTypes': selectedRestaurantTypes,
      'selectedEntries': selectedEntries,
      'selectedSessions': selectedSessions,
      'selectedAdditionals': selectedAdditionals,
      'listMusic': listMusic,

      // Music flags
      'checkMusic': checkMusic,
      'haveMusic': haveMusic,
      'haveSinger': haveSinger,
      'haveDJ': haveDJ,
      'haveOud': haveOud,

      // Facilities list (hotel optional)
      'facilityList': facilityList
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'nameEn': f.nameEn,
                'price': f.price,
              })
          .toList(),

      // Floor plan
      'layoutId': _layoutId,

      // Metro
      // 'metroCity': ((cityValue ?? '').toLowerCase().trim()),
      // 'metroLines': _metroCtrl.chosenLines,
      // 'metroStationsByLine': _metroCtrl.chosenStationsByLine,
    };
  }

  Future<void> _loadDraft() async {
    _restoringDraft = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kDraftKey);
      if (raw == null || raw.isEmpty) return;

      final Map<String, dynamic> map = jsonDecode(raw);

      // If draft was created for another userType, ignore it
      if ((map['userType'] ?? widget.userType) != widget.userType) return;

      _applyDraft(map);
    } finally {
      _restoringDraft = false;
    }
  }

  void _applyDraft(Map<String, dynamic> m) {
    // Texts
    nameController.text = (m['nameAr'] ?? '');
    bioController.text = (m['bioAr'] ?? '');
    enNameController.text = (m['nameEn'] ?? '');
    enBioController.text = (m['bioEn'] ?? '');
    enBranchController.text = (m['branchEn'] ?? '');
    arBranchController.text = (m['branchAr'] ?? '');

    // PDFs
    facilityPdfUrl = (m['facilityPdfUrl'] ?? '') as String?;
    taxPdfUrl = (m['taxPdfUrl'] ?? '') as String?;

    // Photographer
    _dateOfPhotographyController.text = (m['dateOfPhotography'] ?? '');
    _timeOfPhotographyController.text = (m['timeOfPhotography'] ?? '');
    _dayOfPhotography = (m['dayOfPhotography'] ?? '');

    // Menu & phone
    menuLinkController.text = (m['menuLink'] ?? '');
    phoneNumberController.text = (m['estatePhone'] ?? '');

    // // Location
    // countryValue = m['country'];
    // stateValue = m['state'];
    // cityValue = m['city'];

    // Valet / Kids / Smoking
    hasValet = m['hasValet'] ?? false;
    valetWithFees = m['valetWithFees'] ?? false;
    hasKidsArea = m['hasKidsArea'] ?? false;
    checkIsSmokingAllowed = m['isSmokingAllowed'] ?? false;

    // Hotel amenities
    hasSwimmingPool = m['hasSwimmingPool'] ?? false;
    hasJacuzzi = m['hasJacuzzi'] ?? false;
    hasBarber = m['hasBarber'] ?? false;
    hasMassage = m['hasMassage'] ?? false;
    hasGym = m['hasGym'] ?? false;

    // Room toggles & data
    single = m['single'] ?? false;
    double = m['double'] ?? false;
    suite = m['suite'] ?? false;
    family = m['family'] ?? false;
    grandSuite = m['grandSuite'] ?? false;
    businessSuite = m['businessSuite'] ?? false;

    singleController.text = (m['singlePrice'] ?? '');
    doubleController.text = (m['doublePrice'] ?? '');
    suiteController.text = (m['suitePrice'] ?? '');
    familyController.text = (m['familyPrice'] ?? '');
    grandSuiteController.text = (m['grandSuitePrice'] ?? '');
    grandSuiteControllerAr.text = (m['grandSuitePriceAr'] ?? '');
    businessSuiteController.text = (m['businessSuitePrice'] ?? '');
    businessSuiteControllerAr.text = (m['businessSuitePriceAr'] ?? '');

    singleControllerBioAr.text = (m['singleBioAr'] ?? '');
    doubleControllerBioAr.text = (m['doubleBioAr'] ?? '');
    suiteControllerBioAr.text = (m['suiteBioAr'] ?? '');
    familyControllerBioAr.text = (m['familyBioAr'] ?? '');
    singleControllerBioEn.text = (m['singleBioEn'] ?? '');
    doubleControllerBioEn.text = (m['doubleBioEn'] ?? '');
    suiteControllerBioEn.text = (m['suiteBioEn'] ?? '');
    familyControllerBioEn.text = (m['familyBioEn'] ?? '');
    grandSuiteControllerBioEn.text = (m['grandSuiteBioEn'] ?? '');
    grandSuiteControllerBioAr.text = (m['grandSuiteBioAr'] ?? '');
    businessSuiteControllerBioEn.text = (m['businessSuiteBioEn'] ?? '');
    businessSuiteControllerBioAr.text = (m['businessSuiteBioAr'] ?? '');

    breakfastPrice = (m['breakfastPrice'] ?? '');
    launchPrice = (m['launchPrice'] ?? '');
    dinnerPrice = (m['dinnerPrice'] ?? '');

    // Lists
    selectedRestaurantTypes =
        List<String>.from(m['selectedRestaurantTypes'] ?? const []);
    selectedEntries = List<String>.from(m['selectedEntries'] ?? const []);
    selectedSessions = List<String>.from(m['selectedSessions'] ?? const []);
    selectedAdditionals =
        List<String>.from(m['selectedAdditionals'] ?? const []);
    listMusic = List<String>.from(m['listMusic'] ?? const []);

    // Music flags
    checkMusic = m['checkMusic'] ?? false;
    haveMusic = m['haveMusic'] ?? false;
    haveSinger = m['haveSinger'] ?? false;
    haveDJ = m['haveDJ'] ?? false;
    haveOud = m['haveOud'] ?? false;

    // Facilities list
    facilityList.clear();
    final facilities = (m['facilityList'] ?? []) as List<dynamic>;
    for (final f in facilities) {
      facilityList.add(
        Additional(
          id: f['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: f['name'] ?? '',
          nameEn: f['nameEn'] ?? '',
          price: f['price'] ?? '',
          isBool: false,
          color: Colors.white,
        ),
      );
    }

    // Floor plan
    _layoutId = (m['layoutId'] ?? '') == '' ? null : m['layoutId'];

    // Metro restore (best-effort)
    try {
      final lines = List<String>.from(m['metroLines'] ?? const []);
      final stationsByLine = Map<String, dynamic>.from(
          m['metroStationsByLine'] ?? const <String, dynamic>{});
      final casted = stationsByLine.map(
        (k, v) => MapEntry(k, List<String>.from(v ?? const [])),
      );

      // If your MetroSelectionController exposes a restore API, call it here:
      // Example (implement this in your controller if not present):
      // _metroCtrl.restoreSelection(lines, casted);
    } catch (_) {}

    // Refresh UI
    setState(() {});
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }

  void _onRestaurantTypeCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        selectedRestaurantTypes.add(type);
      } else {
        selectedRestaurantTypes.remove(type);
      }
    });
    _saveDraftDebounced(); // NEW
  }

  // bool _hasPartialMetroSelection() {
  //   final lines = _metroCtrl.chosenLines; // selected lines
  //   for (final ln in lines) {
  //     final st =
  //         _metroCtrl.chosenStationsByLine[ln]; // may be null if none chosen
  //     if (st == null || st.isEmpty) return true; // a line with no stations
  //   }
  //   return false;
  // }

  Future<void> saveFacilities(String estateId) async {
    for (var facility in facilityList) {
      DatabaseReference refEstateFacility = FirebaseDatabase.instance
          .ref("App")
          .child("Estate")
          .child("Hottel")
          .child(estateId)
          .child("Fasilty")
          .child(facility.id);

      await refEstateFacility.set({
        "ID": facility.id,
        "Name": facility.name,
        "NameEn": facility.nameEn,
        "Price": facility.price,
      });
    }
  }

  void _onAdditionalCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        selectedAdditionals.add(type);
      } else {
        selectedAdditionals.remove(type);
      }
    });
    _saveDraftDebounced();
  }

  void _onSessionCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        selectedSessions.add(type);
      } else {
        selectedSessions.remove(type);
      }
    });
    _saveDraftDebounced();
  }

  void _onCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        selectedEntries.add(type);
      } else {
        selectedEntries.remove(type);
      }
    });
    _saveDraftDebounced();
  }

  // ===== Validation (combined) =====
  bool _areRequiredFieldsFilled() {
    bool basicFieldsFilled =
        nameController.text.isNotEmpty && enNameController.text.isNotEmpty;
    // enBranchController.text.isNotEmpty &&
    // arBranchController.text.isNotEmpty;
    // &&
    // (countryValue != null && countryValue!.isNotEmpty) &&
    // (stateValue != null && stateValue!.isNotEmpty) &&
    // (cityValue != null && cityValue!.isNotEmpty);

    if (!basicFieldsFilled) return false;

    if (facilityPdfUrl == null || facilityPdfUrl!.isEmpty) return false;
    if (taxPdfUrl == null || taxPdfUrl!.isEmpty) return false;

    if (widget.userType == "1") {
      bool roomTypeSelected =
          single || double || suite || family || grandSuite || businessSuite;
      bool hasAmenity =
          hasSwimmingPool || hasJacuzzi || hasBarber || hasMassage || hasGym;
      return roomTypeSelected && hasAmenity;
    }

    if (widget.userType == "2") {
      bool sessionsOk = selectedSessions.isNotEmpty;
      bool entriesOk = selectedEntries.isNotEmpty;
      return sessionsOk && entriesOk;
    }

    if (widget.userType == "3") {
      bool restaurantTypeOk = selectedRestaurantTypes.isNotEmpty;
      bool sessionsOk = selectedSessions.isNotEmpty;
      bool entriesOk = selectedEntries.isNotEmpty;
      return restaurantTypeOk && sessionsOk && entriesOk;
    }

    return basicFieldsFilled;
  }

  // ===== First missing anchor =====
  GlobalKey? _getFirstMissingAnchor() {
    if (nameController.text.isEmpty) return _keyNameArField;
    if (enNameController.text.isEmpty) return _keyNameEnField;
    // if (enBranchController.text.isEmpty) return _keyBranchEnField;
    // if (arBranchController.text.isEmpty) return _keyBranchArField;

    // if ((countryValue == null || countryValue!.isNotEmpty == false) ||
    //     (stateValue == null || stateValue!.isNotEmpty == false) ||
    //     (cityValue == null || cityValue!.isNotEmpty == false)) {
    //   return _keyLocation;
    // }

    if (facilityPdfUrl == null || facilityPdfUrl!.isEmpty) return _keyLegal;
    if (taxPdfUrl == null || taxPdfUrl!.isEmpty) return _keyLegal;

    if (widget.userType == "1") {
      if (!(single ||
          double ||
          suite ||
          family ||
          grandSuite ||
          businessSuite)) {
        return _keyHotelRooms;
      }
      if (!(hasSwimmingPool ||
          hasJacuzzi ||
          hasBarber ||
          hasMassage ||
          hasGym)) {
        return _keyAmenitiesHotel;
      }
    } else if (widget.userType == "2") {
      if (selectedEntries.isEmpty) return _keyEntry;
      if (selectedSessions.isEmpty) return _keySessions;
    } else if (widget.userType == "3") {
      if (selectedRestaurantTypes.isEmpty) return _keyRestaurantType;
      if (selectedEntries.isEmpty) return _keyEntry;
      if (selectedSessions.isEmpty) return _keySessions;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    // Prepare any server-side data you already load
    backendService.getIdEstate().then((id) {
      setState(() => idEstate = id);
    });

    // Wire all text controllers for autosave
    _wireDraftAutosave();

    // Try to restore an existing draft (if any)
    // Do not await here: build should not block
    _loadDraft();
  }

  Future<String?> getTypeAccount(String userId) async {
    return await backendService.getTypeAccount(userId);
  }

  @override
  Widget build(BuildContext context) {
    btnLogin = Text(
      getTranslated(context, "Next"),
      style: const TextStyle(color: Colors.white),
    );
    final bool isAr = _isArabic(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        actions: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const LanguageDialogWidget();
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.language, color: kPrimaryColor, size: 30),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsetsDirectional.only(bottom: 20),
            child: SafeArea(
              child: ListView(
                key: const PageStorageKey('add_estates_list'),
                controller: _scrollController,
                children: [
                  25.kH,
                  // Arabic info
                  Container(
                    key: _keyInfoAr,
                    child: const ReusedProviderEstateContainer(
                      hint: "Information in Arabic",
                    ),
                  ),
                  // Arabic Name (exact anchor)
                  Container(
                    key: _keyNameArField,
                    child: TextFormFieldStyle(
                      context: context,
                      hint: "Name",
                      icon: Icon(
                        widget.userType != "1" ? Icons.restaurant : Icons.hotel,
                        color: kDeepPurpleColor,
                      ),
                      control: nameController,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Bio",
                    icon: Icon(
                      Icons.description,
                      color: kDeepPurpleColor,
                    ),
                    control: bioController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.text,
                  ),
                  40.kH,
                  // English info
                  Container(
                    key: _keyInfoEn,
                    child: const ReusedProviderEstateContainer(
                      hint: "Information in English",
                    ),
                  ),
                  // English Name (exact anchor)
                  Container(
                    key: _keyNameEnField,
                    child: TextFormFieldStyle(
                      context: context,
                      hint: "Name",
                      icon: Icon(
                        widget.userType != "1" ? Icons.restaurant : Icons.hotel,
                        color: kDeepPurpleColor,
                      ),
                      control: enNameController,
                      isObsecured: false,
                      validate: true,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Bio",
                    icon: Icon(
                      Icons.description,
                      color: kDeepPurpleColor,
                    ),
                    control: enBioController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.text,
                  ),
                  // 40.kH,
                  // // Branch EN
                  // Container(
                  //   key: _keyBranchEn,
                  //   child: const ReusedProviderEstateContainer(
                  //     hint: "Branch in English",
                  //   ),
                  // ),
                  // // Branch EN field (exact anchor)
                  // Container(
                  //   key: _keyBranchEnField,
                  //   child: TextFormFieldStyle(
                  //     context: context,
                  //     hint: "Branch name (Required)",
                  //     icon: Icon(
                  //       Icons.location_on,
                  //       color: kDeepPurpleColor,
                  //     ),
                  //     control: enBranchController,
                  //     isObsecured: false,
                  //     validate: true,
                  //     textInputType: TextInputType.text,
                  //   ),
                  // ),
                  // 40.kH,
                  // // Branch AR
                  // Container(
                  //   key: _keyBranchAr,
                  //   child: const ReusedProviderEstateContainer(
                  //     hint: "Branch in Arabic",
                  //   ),
                  // ),
                  // // Branch AR field (exact anchor)
                  // Container(
                  //   key: _keyBranchArField,
                  //   child: TextFormFieldStyle(
                  //     context: context,
                  //     hint: "Branch name (Required)",
                  //     icon: Icon(
                  //       Icons.location_on,
                  //       color: kDeepPurpleColor,
                  //     ),
                  //     control: arBranchController,
                  //     isObsecured: false,
                  //     validate: true,
                  //     textInputType: TextInputType.text,
                  //   ),
                  // ),
                  40.kH,
                  // Legal
                  Row(
                    children: [
                      Container(
                        key: _keyLegal,
                        child: const ReusedProviderEstateContainer(
                          hint: "Legal information",
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20, top: 10),
                        child: Text(
                          getTranslated(context, "(Required)"),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      )
                    ],
                  ),

                  // ===== Facility PDF upload =====
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                        start: 50, end: 50, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(
                              context, "Upload Facility Document (PDF)"),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        10.kH,
                        ElevatedButton.icon(
                          icon:
                              Icon(Icons.upload_file, color: kDeepPurpleColor),
                          label: isUploadingFacility
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: kDeepPurpleColor,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(getTranslated(context, "Upload PDF")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                            foregroundColor: kDeepPurpleColor,
                            side: BorderSide(color: kDeepPurpleColor, width: 2),
                          ),
                          onPressed: () async {
                            setState(() {
                              isUploadingFacility = true;
                            });

                            try {
                              FilePickerResult? result =
                                  await backendService.openSinglePdf();
                              if (result != null &&
                                  result.files.single.path != null) {
                                String pdfPath = result.files.single.path!;
                                String? pdfUrl = await backendService
                                    .uploadFacilityPdfToStorage(
                                        pdfPath, idEstate.toString());

                                if (pdfUrl != null) {
                                  setState(() {
                                    facilityPdfUrl = pdfUrl;
                                  });
                                  await _saveDraftImmediate(); // <-- NEW
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(getTranslated(context,
                                          "PDF uploaded successfully")),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(getTranslated(
                                          context, "Failed to upload PDF")),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated(
                                        context, "No file selected")),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              // ignore: avoid_print
                              print("Error during PDF upload: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(context,
                                      "An error occurred during upload")),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() {
                                isUploadingFacility = false;
                              });
                            }
                          },
                        ),
                        10.kH,
                        if (isUploadingFacility)
                          Text(
                            getTranslated(context, "Uploading..."),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        if (facilityPdfUrl != null &&
                            facilityPdfUrl!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      getTranslated(context, "PDF Uploaded"),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        facilityPdfUrl = "";
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                height: 300,
                                child: PDF().cachedFromUrl(
                                  facilityPdfUrl!,
                                  placeholder: (progress) =>
                                      Center(child: Text('$progress %')),
                                  errorWidget: (error) => const Center(
                                      child: Text('Error loading PDF')),
                                ),
                              ),
                            ],
                          ),

                        // ===== Tax PDF upload =====
                        Text(
                          getTranslated(context, "Upload Tax Number (PDF)"),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        10.kH,
                        ElevatedButton.icon(
                          icon:
                              Icon(Icons.upload_file, color: kDeepPurpleColor),
                          label: isUploadingTax
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: kDeepPurpleColor,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(getTranslated(context, "Upload PDF")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                            foregroundColor: kDeepPurpleColor,
                            side: BorderSide(color: kDeepPurpleColor, width: 2),
                          ),
                          onPressed: () async {
                            setState(() {
                              isUploadingTax = true;
                            });

                            try {
                              FilePickerResult? result =
                                  await backendService.openSinglePdf();
                              if (result != null &&
                                  result.files.single.path != null) {
                                String pdfPath = result.files.single.path!;
                                String? pdfUrl =
                                    await backendService.uploadTaxPdfToStorage(
                                        pdfPath, idEstate.toString());

                                if (pdfUrl != null) {
                                  setState(() {
                                    taxPdfUrl = pdfUrl;
                                  });
                                  await _saveDraftImmediate(); // <-- NEW
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(getTranslated(context,
                                          "PDF uploaded successfully")),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(getTranslated(
                                          context, "Failed to upload PDF")),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated(
                                        context, "No file selected")),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              // ignore: avoid_print
                              print("Error during PDF upload: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(context,
                                      "An error occurred during upload")),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() {
                                isUploadingTax = false;
                              });
                            }
                          },
                        ),
                        10.kH,
                        if (isUploadingTax)
                          Text(
                            getTranslated(context, "Uploading..."),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        if (taxPdfUrl != null && taxPdfUrl!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      getTranslated(context, "PDF Uploaded"),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        taxPdfUrl = "";
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                height: 300,
                                child: PDF().cachedFromUrl(
                                  taxPdfUrl!,
                                  placeholder: (progress) =>
                                      Center(child: Text('$progress %')),
                                  errorWidget: (error) => const Center(
                                      child: Text('Error loading PDF')),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Photographer date (optional)
                  // Photographer visit (optional)
                  const SizedBox(height: 20),
                  const ReusedProviderEstateContainer(
                      hint: "Photographer Visit (Optional)"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date picker (auto-computes DayOfPhotography)
                        TextFormField(
                          controller: _dateOfPhotographyController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: getTranslated(
                                context, "Choose a date for photography"),
                            prefixIcon:
                                Icon(Icons.camera_alt, color: kDeepPurpleColor),
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                            hintText:
                                getTranslated(context, "Tap to select a date"),
                          ),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.add(const Duration(days: 2)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              // yyyy-MM-dd (DB-friendly)
                              _dateOfPhotographyController.text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                              // DayOfPhotography (e.g., Monday)
                              _dayOfPhotography =
                                  DateFormat('EEEE').format(picked);
                              setState(
                                  () {}); // if you want to reflect the chosen day somewhere
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Time picker (24h like 17:00)
                        TextFormField(
                          controller: _timeOfPhotographyController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: getTranslated(context, "Available time"),
                            prefixIcon: Icon(Icons.access_time,
                                color: kDeepPurpleColor),
                            suffixIcon: const Icon(Icons.schedule),
                            border: const OutlineInputBorder(),
                            hintText: "HH:mm",
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 17, minute: 0),
                              builder: (ctx, child) =>
                                  child ?? const SizedBox.shrink(),
                            );
                            if (picked != null) {
                              // Force 24h HH:mm
                              final dt =
                                  DateTime(0, 1, 1, picked.hour, picked.minute);
                              _timeOfPhotographyController.text =
                                  DateFormat('HH:mm').format(dt);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  10.kH,
                  if (widget.userType == "2" || widget.userType == "3") ...[
                    20.kH,
                    Container(
                      key: _keyFloorPlan,
                      child: const ReusedProviderEstateContainer(
                        hint: "Floor Plan (Optional)",
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (idEstate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Please wait, loading…")),
                                );
                                return;
                              }

                              final childType = widget.userType == "2"
                                  ? "Coffee"
                                  : "Restaurant";

                              final layout =
                                  await Navigator.push<AutoCadLayout?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeatMapBuilderScreen(
                                    childType: childType,
                                    estateId: idEstate!.toString(),
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
                                      content: Text(getTranslated(
                                          context, "Floor plan ready"))),
                                );
                              }
                            },
                            child: Text(
                              _layoutId == null
                                  ? getTranslated(
                                      context, "Configure Floor Plan")
                                  : getTranslated(
                                      context, "Reconfigure Floor Plan"),
                            ),
                          ),
                          if (_layoutId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "${getTranslated(context, "Configured Layout ID:")} $_layoutId",
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  10.kH,

                  40.kH,
                  Container(
                    key: _keyMenu,
                    child: const ReusedProviderEstateContainer(
                      hint: "Menu",
                    ),
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Enter Menu Link",
                    icon: Icon(
                      Icons.link,
                      color: kDeepPurpleColor,
                    ),
                    control: menuLinkController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.url,
                  ),
                  20.kH,
                  Container(
                    key: _keyPhone,
                    child: const ReusedProviderEstateContainer(
                      hint: "Phone number",
                    ),
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Enter your Phone Number",
                    icon: Icon(
                      Icons.phone,
                      color: kDeepPurpleColor,
                    ),
                    control: phoneNumberController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.url,
                  ),

                  // Hotel additional services list (optional UI)
                  Visibility(
                    visible: widget.userType == "1" ? true : false,
                    child: Container(
                      key: _keyFacilitiesHotel,
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
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (facilityNameController.text.isNotEmpty &&
                                  facilityNameArController.text.isNotEmpty &&
                                  facilityPriceController.text.isNotEmpty) {
                                String id = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                Additional facility = Additional(
                                  id: id,
                                  name: facilityNameArController.text,
                                  nameEn: facilityNameController.text,
                                  price: facilityPriceController.text,
                                  isBool: false,
                                  color: Colors.white,
                                );
                                setState(() {
                                  facilityList.add(facility);
                                });
                                facilityNameController.clear();
                                facilityNameArController.clear();
                                facilityPriceController.clear();
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
                                        title: Text(facility.name),
                                        subtitle: Text(facility.price),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              facilityList.removeAt(index);
                                            });
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

                  // Restaurant type (Restaurant)
                  Visibility(
                    visible: widget.userType == "3" ? true : false,
                    child: Row(
                      children: [
                        Container(
                          key: _keyRestaurantType,
                          child: const ReusedProviderEstateContainer(
                            hint: "Type of Restaurant",
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
                          child: Text(
                            getTranslated(context, "(Select at least 1)"),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                      start: 30,
                    ),
                    padding: (const EdgeInsets.only(right: 25)),
                    child: RestaurantTypeVisibility(
                      isVisible: widget.userType == "3",
                      onCheckboxChanged: _onRestaurantTypeCheckboxChanged,
                      selectedRestaurantTypes: selectedRestaurantTypes,
                    ),
                  ),
                  15.kH,

                  // Entry allowed (Restaurant/Coffee)
                  Visibility(
                    visible: widget.userType == "3" || widget.userType == "2"
                        ? true
                        : false,
                    child: Row(
                      children: [
                        Container(
                          key: _keyEntry,
                          child: const ReusedProviderEstateContainer(
                            hint: "Entry allowed",
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
                          child: Text(
                            getTranslated(context, "(Select at least 1)"),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                      start: 50,
                    ),
                    child: EntryVisibility(
                      isVisible:
                          widget.userType == "3" || widget.userType == "2",
                      onCheckboxChanged: _onCheckboxChanged,
                      selectedEntries: selectedEntries,
                    ),
                  ),

                  // Sessions (Restaurant/Coffee)
                  Visibility(
                    visible: widget.userType == "3" || widget.userType == "2"
                        ? true
                        : false,
                    child: Row(
                      children: [
                        Container(
                          key: _keySessions,
                          child: const ReusedProviderEstateContainer(
                            hint: 'Sessions type',
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
                          child: Text(
                            getTranslated(context, "(Select at least 1)"),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 50),
                    child: SessionsVisibility(
                      isVisible:
                          widget.userType == "3" || widget.userType == "2",
                      onCheckboxChanged: _onSessionCheckboxChanged,
                      selectedSessions: selectedSessions,
                    ),
                  ),

                  40.kH,

                  // Additionals (Restaurant/Coffee)
                  Visibility(
                    visible: widget.userType == "3" || widget.userType == "2"
                        ? true
                        : false,
                    child: const ReusedProviderEstateContainer(
                      hint: "Additionals",
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                      start: 50,
                    ),
                    child: AdditionalsRestaurantCoffee(
                      isVisible:
                          widget.userType == "3" || widget.userType == "2",
                      onCheckboxChanged: _onAdditionalCheckboxChanged,
                      selectedAdditionals: selectedAdditionals,
                    ),
                  ),
                  40.kH,

                  // Music (optional)
                  Container(
                    key: _keyMusic,
                    margin: const EdgeInsetsDirectional.only(
                      start: 50,
                    ),
                    child: MusicVisibility(
                      isVisible:
                          widget.userType == "3" || widget.userType == "2",
                      checkMusic: checkMusic,
                      haveMusic: haveMusic,
                      haveSinger: haveSinger,
                      haveDJ: haveDJ,
                      haveOud: haveOud,
                      onMusicChanged: (value) {
                        setState(() {
                          checkMusic = value;
                          if (!checkMusic) {
                            haveMusic = false;
                            haveSinger = false;
                            haveDJ = false;
                            haveOud = false;
                            listMusic.clear();
                          } else if (widget.userType == "2") {
                            haveMusic = true;
                          }
                        });
                      },
                      onSingerChanged: (value) {
                        setState(() {
                          haveSinger = value;
                          if (value) {
                            listMusic.add("singer");
                          } else {
                            listMusic.remove("singer");
                          }
                        });
                      },
                      onDJChanged: (value) {
                        setState(() {
                          haveDJ = value;
                          if (value) {
                            listMusic.add("DJ");
                          } else {
                            listMusic.remove("DJ");
                          }
                        });
                      },
                      onOudChanged: (value) {
                        setState(() {
                          haveOud = value;
                          if (value) {
                            listMusic.add("Oud");
                          } else {
                            listMusic.remove("Oud");
                          }
                        });
                      },
                    ),
                  ),

                  // Valet (optional)
                  Container(
                    key: _keyValet,
                    child: const ReusedProviderEstateContainer(
                      hint: "Valet Options",
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 50),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title:
                              Text(getTranslated(context, "Is there valet?")),
                          value: hasValet,
                          onChanged: (bool? value) {
                            setState(() {
                              hasValet = value ?? false;
                              valetWithFees = false;
                            });
                            _saveDraftDebounced();
                          },
                          activeColor: kPurpleColor,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        Visibility(
                          visible: hasValet,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                title: Text(
                                    getTranslated(context, "Valet with fees")),
                                value: valetWithFees,
                                onChanged: (bool? value) {
                                  setState(() {
                                    valetWithFees = value ?? false;
                                  });
                                  _saveDraftDebounced();
                                },
                                activeColor: kDeepPurpleColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              Visibility(
                                visible: !valetWithFees,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 16.0),
                                  child: Text(
                                    getTranslated(context,
                                        "If valet with fees is not selected, valet service is free."),
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kids (optional)
                  Visibility(
                    visible: widget.userType == "2" || widget.userType == "3",
                    child: Container(
                      key: _keyKids,
                      child: const ReusedProviderEstateContainer(
                        hint: "Kids Area Options",
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "2" || widget.userType == "3",
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 50),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(
                                getTranslated(context, "Is there Kids Area?")),
                            value: hasKidsArea,
                            onChanged: (bool? value) {
                              setState(() {
                                hasKidsArea = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Smoking (optional)
                  Container(
                    key: _keySmoking,
                    child: const ReusedProviderEstateContainer(
                      hint: "Smoking Area?",
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "2" || widget.userType == "3",
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 50),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(
                                getTranslated(context, "Is Smoking Allowed?")),
                            value: checkIsSmokingAllowed,
                            onChanged: (bool? value) {
                              setState(() {
                                checkIsSmokingAllowed = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "1",
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 50),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(getTranslated(
                                context, "Is Smoking Allowed in some rooms?")),
                            value: checkIsSmokingAllowed,
                            onChanged: (bool? value) {
                              setState(() {
                                checkIsSmokingAllowed = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hotel amenities
                  Visibility(
                    visible: widget.userType == "1",
                    child: Container(
                      key: _keyAmenitiesHotel,
                      child: const ReusedProviderEstateContainer(
                        hint: "Hotel Amenities",
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "1",
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 50),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(getTranslated(
                                context, "Is there Swimming Pool?")),
                            value: hasSwimmingPool,
                            onChanged: (bool? value) {
                              setState(() {
                                hasSwimmingPool = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            title: Text(
                                getTranslated(context, "Is there Jacuzzi?")),
                            value: hasJacuzzi,
                            onChanged: (bool? value) {
                              setState(() {
                                hasJacuzzi = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            title: Text(
                                getTranslated(context, "Is there Barber?")),
                            value: hasBarber,
                            onChanged: (bool? value) {
                              setState(() {
                                hasBarber = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            title: Text(
                                getTranslated(context, "Is there Massage?")),
                            value: hasMassage,
                            onChanged: (bool? value) {
                              setState(() {
                                hasMassage = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            title:
                                Text(getTranslated(context, "Is there Gym?")),
                            value: hasGym,
                            onChanged: (bool? value) {
                              setState(() {
                                hasGym = value ?? false;
                              });
                              _saveDraftDebounced();
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    key: _keyLocation,
                    child: const ReusedProviderEstateContainer(
                      hint: "Location",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      getTranslated(context,
                          "You will set the estate location on the map in the next step."),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  40.kH,

                  // Location
                  // Container(
                  //   key: _keyLocation,
                  //   child: const ReusedProviderEstateContainer(
                  //     hint: "Location information",
                  //   ),
                  // ),
                  // 20.kH,
                  // CustomCSCPicker(
                  //   key: const PageStorageKey('location_picker'),
                  //   onCountryChanged: (value) {
                  //     setState(() {
                  //       countryValue = value;
                  //     });
                  //     _saveDraftDebounced();
                  //   },
                  //   onStateChanged: (value) {
                  //     setState(() {
                  //       stateValue = value;
                  //     });
                  //     _saveDraftDebounced();
                  //   },
                  //   onCityChanged: (value) {
                  //     setState(() {
                  //       cityValue = value;
                  //     });
                  //     _saveDraftDebounced();
                  //   },
                  // ),
                  //
                  // // ===== Nearby Riyadh Metro (REFACTORED) =====
                  // RiyadhMetroPicker(
                  //   key: _keyMetro,
                  //   controller: _metroCtrl,
                  //   isVisible:
                  //       (cityValue ?? '').toLowerCase().trim() == 'riyadh',
                  // ),

                  // Hotel rooms
                  Visibility(
                    visible: widget.userType == "1" ? true : false,
                    child: Container(
                      key: _keyHotelRooms,
                      child: const ReusedProviderEstateContainer(
                          hint: "What We have ?"),
                    ),
                  ),
                  RoomTypeVisibility(
                    userType: widget.userType,
                    onCheckboxChanged: (value, type) {
                      setState(() {
                        if (type == "IsSmokingAllowed") {
                          checkIsSmokingAllowed = value;
                        } else if (type == "IsThereBreakfastLounge") {
                          checkIsThereBreakfastLounge = value;
                        } else if (type == "IsThereLaunchLounge") {
                          checkIsThereLaunchLounge = value;
                        } else if (type == "IsThereDinnerLounge") {
                          checkIsThereDinnerLounge = value;
                        }
                      });
                    },
                    onBreakfastPriceChanged: (value) {
                      setState(() => breakfastPrice = value);
                    },
                    onLaunchPriceChanged: (value) {
                      setState(() => launchPrice = value);
                    },
                    onDinnerPriceChanged: (value) {
                      setState(() => dinnerPrice = value);
                    },
                    single: single,
                    double: double,
                    suite: suite,
                    family: family,
                    grandSuite: grandSuite,
                    businessSuite: businessSuite,
                    businessSuiteControllerBioEn: businessSuiteControllerBioEn,
                    businessSuiteControllerBioAr: businessSuiteControllerBioAr,
                    grandSuiteControllerBioEn: grandSuiteControllerBioEn,
                    grandSuiteControllerBioAr: grandSuiteControllerBioAr,
                    singleHotelRoomController: singleController,
                    doubleHotelRoomController: doubleController,
                    suiteHotelRoomController: suiteController,
                    familyHotelRoomController: familyController,
                    grandSuiteController: grandSuiteController,
                    grandSuiteControllerAr: grandSuiteControllerAr,
                    businessSuiteController: businessSuiteController,
                    businessSuiteControllerAr: businessSuiteControllerAr,
                    singleHotelRoomControllerBioAr: singleControllerBioAr,
                    singleHotelRoomControllerBioEn: singleControllerBioEn,
                    doubleHotelRoomControllerBioEn: doubleControllerBioEn,
                    doubleHotelRoomControllerBioAr: doubleControllerBioAr,
                    suiteHotelRoomControllerBioEn: suiteControllerBioEn,
                    suiteHotelRoomControllerBioAr: suiteControllerBioAr,
                    familyHotelRoomControllerBioAr: familyControllerBioAr,
                    familyHotelRoomControllerBioEn: familyControllerBioEn,
                    onSingleChanged: (value) {
                      setState(() {
                        single = value;
                      });
                    },
                    onGrandChanged: (value) {
                      setState(() {
                        grandSuite = value;
                      });
                    },
                    onBusinessChanged: (value) {
                      setState(() {
                        businessSuite = value;
                      });
                    },
                    onDoubleChanged: (value) {
                      setState(() {
                        double = value;
                      });
                    },
                    onSuiteChanged: (value) {
                      setState(() {
                        suite = value;
                      });
                    },
                    onFamilyChanged: (value) {
                      setState(() {
                        family = value;
                      });
                    },
                  ),
                  CustomButton(
                      text: getTranslated(context, "Next"),
                      onPressed: () async {
                        // Validate
                        if (!_areRequiredFieldsFilled()) {
                          final anchor = _getFirstMissingAnchor();
                          if (anchor != null) {
                            _scrollTo(anchor);
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const FailureDialog(
                                text: "Incomplete Information",
                                text1:
                                    "Please fill out all required fields before proceeding.",
                              );
                            },
                          );
                          return;
                        }

                        if (facilityPdfUrl == null || facilityPdfUrl!.isEmpty) {
                          _scrollTo(_keyLegal);
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const FailureDialog(
                                text: "PDF Not Uploaded",
                                text1:
                                    "Please upload the Commercial Registration PDF before proceeding.",
                              );
                            },
                          );
                          return;
                        }
                        if (taxPdfUrl == null || taxPdfUrl!.isEmpty) {
                          _scrollTo(_keyLegal);
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const FailureDialog(
                                text: "PDF Not Uploaded",
                                text1:
                                    "Please upload the Tax Number PDF before proceeding.",
                              );
                            },
                          );
                          return;
                        }

                        // Build Metro payload intent (only if Riyadh)
                        // final bool isRiyadh =
                        //     (cityValue ?? '').toLowerCase().trim() == 'riyadh';
                        // List<String> selectedLines =
                        //     _metroCtrl.chosenLines; // EN
                        // Map<String, List<String>> selectedStations =
                        //     _metroCtrl.chosenStationsByLine; // EN
                        //
                        // if (isRiyadh &&
                        //     selectedLines.isNotEmpty &&
                        //     _hasPartialMetroSelection()) {
                        //   final proceed = await showDialog<bool>(
                        //     context: context,
                        //     builder: (ctx) => AlertDialog(
                        //       title: const Text("Metro selection incomplete"),
                        //       content: Text(
                        //         "${getTranslated(context, "You selected at least one metro line but did not choose any station on it.")}\n\n"
                        //         "${getTranslated(context, "Do you want to continue without saving any Metro info?")}",
                        //       ),
                        //       actions: [
                        //         TextButton(
                        //           onPressed: () => Navigator.of(ctx).pop(false),
                        //           child: Text(getTranslated(
                        //               context, 'Choose stations')),
                        //         ),
                        //         ElevatedButton(
                        //           onPressed: () => Navigator.of(ctx).pop(true),
                        //           child:
                        //               Text(getTranslated(context, 'Continue')),
                        //         ),
                        //       ],
                        //     ),
                        //   );
                        //
                        //   if (proceed != true) {
                        //     _scrollTo(_keyMetro);
                        //     return;
                        //   } else {
                        //     selectedLines = const [];
                        //     selectedStations = const {};
                        //   }
                        // }

                        // --- BLOCKING LOADER (kept up until *everything* is done) ---
                        showCustomLoadingDialog(
                            context); // barrierDismissible: false in your impl

                        try {
                          String childType;
                          if (widget.userType == "1") {
                            childType = "Hottel";
                          } else if (widget.userType == "2") {
                            childType = "Coffee";
                          } else {
                            childType = "Restaurant";
                          }

                          final music = checkMusic ? "1" : "0";
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            throw Exception("User not logged in");
                          }

                          final userID = user.uid;
                          final userRef = FirebaseDatabase.instance
                              .ref('App')
                              .child('User')
                              .child(userID);
                          final snapshot = await userRef.get();

                          Map<String, dynamic> userDetails = {};
                          if (snapshot.exists && snapshot.value != null) {
                            userDetails = Map<String, dynamic>.from(
                                snapshot.value as Map);
                          }

                          final String? firstName = userDetails["FirstName"];
                          final String? lastName = userDetails["LastName"];
                          final String? typeAccount =
                              userDetails["TypeAccount"];

                          if (firstName == null ||
                              firstName.isEmpty ||
                              lastName == null ||
                              lastName.isEmpty) {
                            // Keep loader up? We should dismiss before showing another dialog.
                            if (Navigator.of(context).canPop())
                              Navigator.of(context).pop();
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title:
                                      const Text("Missing Owner Information"),
                                  content: const Text(
                                    "Your personal information is missing. Please fill out all your personal information in order to add an estate.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PersonalInfoScreen(
                                              email: userDetails['Email'] ?? '',
                                              phoneNumber:
                                                  userDetails['PhoneNumber'] ??
                                                      '',
                                              password:
                                                  userDetails['Password'] ?? '',
                                              typeUser:
                                                  userDetails['TypeUser'] ?? '',
                                              typeAccount:
                                                  userDetails['TypeAccount'] ??
                                                      '',
                                              firstName:
                                                  userDetails['FirstName'] ??
                                                      '',
                                              secondName:
                                                  userDetails['SecondName'] ??
                                                      '',
                                              lastName:
                                                  userDetails['LastName'] ?? '',
                                              city: userDetails['City'] ?? '',
                                              country:
                                                  userDetails['Country'] ?? '',
                                              state: userDetails['State'] ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Update Info"),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          // Build room listEntry for hotels
                          if (widget.userType == "1") {
                            listEntry.clear();
                            if (single) listEntry.add("Single");
                            if (double) listEntry.add("Double");
                            if (suite) listEntry.add("Suite");
                            if (family) listEntry.add("Hotel Apartments");
                            if (grandSuite) listEntry.add('Grand Suite');
                            if (businessSuite) listEntry.add('Business Suite');
                          }

                          // Add estate (await)
                          await backendService.addEstate(
                            childType: childType,
                            idEstate: idEstate.toString(),
                            nameAr: nameController.text,
                            nameEn: enNameController.text,
                            branchEn: "", // will be filled in MapsScreen
                            branchAr: "", // will be filled in MapsScreen
                            bioAr: bioController.text,
                            bioEn: enBioController.text,
                            country: "",
                            city: "",
                            state: "",
                            userType: widget.userType,
                            userID: userID,
                            typeAccount: typeAccount ?? "",
                            taxNumber: taxNumberController.text,
                            music: music,
                            listTypeOfRestaurant: selectedRestaurantTypes,
                            listSessions: selectedSessions,
                            roomAllowance: roomAllowance,
                            additionals: selectedAdditionals,
                            listMusic: listMusic,
                            listEntry: widget.userType != "1"
                                ? selectedEntries
                                : listEntry,
                            price: singleController.text.isNotEmpty
                                ? singleController.text
                                : "150",
                            priceLast: familyController.text.isNotEmpty
                                ? familyController.text
                                : "1500",
                            dateOfPhotography:
                                _dateOfPhotographyController.text,
                            dayOfPhotography: _dayOfPhotography ?? "",
                            timeOfPhotography:
                                _timeOfPhotographyController.text,
                            ownerFirstName: firstName,
                            ownerLastName: lastName,
                            menuLink: menuLinkController.text,
                            estatePhoneNumber: phoneNumberController.text,
                            hasValet: hasValet,
                            valetWithFees: valetWithFees,
                            hasKidsArea: hasKidsArea,
                            hasSwimmingPool: hasSwimmingPool,
                            hasJacuzzi: hasJacuzzi,
                            hasBarber: hasBarber,
                            hasMassage: hasMassage,
                            hasGym: hasGym,
                            isSmokingAllowed: checkIsSmokingAllowed,
                            isThereBreakfastLounge: checkIsThereBreakfastLounge,
                            isThereLaunchLounge: checkIsThereLaunchLounge,
                            isThereDinnerLounge: checkIsThereDinnerLounge,
                            facilityImageUrl: facilityPdfUrl ?? "",
                            taxImageUrl: taxPdfUrl ?? "",
                            breakfastLoungePrice: breakfastPrice.isNotEmpty
                                ? breakfastPrice
                                : "0",
                            launchLoungePrice:
                                launchPrice.isNotEmpty ? launchPrice : "0",
                            dinnerLoungePrice:
                                dinnerPrice.isNotEmpty ? dinnerPrice : "0",
                            layoutId: _layoutId,
                            // metroCity: isRiyadh ? 'Riyadh' : '',
                            // metroLines: isRiyadh ? selectedLines : const [],
                            // metroStationsByLine:
                            //     isRiyadh ? selectedStations : const {},
                          );

                          // Add rooms (await each)
                          final String ID = idEstate.toString();
                          if (single) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "1",
                              roomName: "Single",
                              roomPrice: singleController.text,
                              roomBioAr: singleControllerBioAr.text,
                              roomBioEn: singleControllerBioEn.text,
                            );
                          }
                          if (double) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "2",
                              roomName: "Double",
                              roomPrice: doubleController.text,
                              roomBioAr: doubleControllerBioAr.text,
                              roomBioEn: doubleControllerBioEn.text,
                            );
                          }
                          if (suite) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "3",
                              roomName: "Suite",
                              roomPrice: suiteController.text,
                              roomBioAr: suiteControllerBioAr.text,
                              roomBioEn: suiteControllerBioEn.text,
                            );
                          }
                          if (family) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "4",
                              roomName: "Family",
                              roomPrice: familyController.text,
                              roomBioAr: familyControllerBioAr.text,
                              roomBioEn: familyControllerBioEn.text,
                            );
                          }
                          if (grandSuite) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "5",
                              roomName: "Grand Suite",
                              roomPrice: grandSuiteController.text,
                              roomBioAr: grandSuiteControllerBioAr.text,
                              roomBioEn: grandSuiteControllerBioEn.text,
                            );
                          }
                          if (businessSuite) {
                            await backendService.addRoom(
                              estateId: ID,
                              roomId: "6",
                              roomName: "Business Suite",
                              roomPrice: businessSuiteController.text,
                              roomBioAr: businessSuiteControllerBioAr.text,
                              roomBioEn: businessSuiteControllerBioEn.text,
                            );
                          }

                          // Facilities
                          await saveFacilities(ID);

                          // Increment ID (await)
                          idEstate = (idEstate! + 1);
                          await backendService.updateEstateId(idEstate!);

                          // 🔒 Upload AutoCAD layout BEFORE dismissing loader
                          if (_pendingLayout != null) {
                            await backendService.uploadAutoCadLayout(
                              childType: childType,
                              estateId: ID,
                              layout: _pendingLayout!,
                            );
                          }

                          // ✅ Everything is done — now dismiss loader and navigate
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context)
                                .pop(); // dismiss loading dialog
                          }
                          if (!mounted) return;

// Remove the saved draft because we finished successfully
                          await _clearDraft(); // <-- NEW

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) =>
                                    MapsScreen(id: ID, typeEstate: childType)),
                            (Route<dynamic> route) => false,
                          );
                        } catch (e) {
                          // Make sure loader is dismissed on error
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                          // Surface a readable error
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Failed to add estate"),
                              content: Text(e.toString()),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text("OK")),
                              ],
                            ),
                          );
                        }
                      })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
