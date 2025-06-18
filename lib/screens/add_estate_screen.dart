import 'package:daimond_host_provider/backend/adding_estate_services.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
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
  List<XFile>? imageFiles;
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
  String? countryValue;
  late String? stateValue;
  late String? cityValue;
  int? idEstate;
  late Widget btnLogin;
  String breakfastPrice = '';
  String launchPrice = '';
  String dinnerPrice = '';

  // New valet variables
  bool hasValet = false;
  bool valetWithFees = false;

  // New kids area variables
  bool hasKidsArea = false;
  bool isSmokingAllowed = false;

  // New hotel-specific variables
  bool hasSwimmingPool = false;
  bool hasJacuzzi = false;
  bool hasBarber = false;
  bool hasMassage = false;
  bool hasGym = false;

  // New isUploading variable to track the upload process
  bool isUploadingFacility = false;
  bool isUploadingTax = false;

  // New state variable to store the PDF URL
  String? facilityPdfUrl;
  String? taxPdfUrl;
  List<String> selectedEntries = [];
  List<String> selectedSessions = [];
  List<String> selectedAdditionals = [];
  List<String> selectedRestaurantTypes = [];

  void _onRestaurantTypeCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        // Add to the list if checked
        selectedRestaurantTypes.add(type);
      } else {
        // Remove from the list if unchecked
        selectedRestaurantTypes.remove(type);
      }
    });
  }

  Future<void> saveFacilities(String estateId) async {
    for (var facility in facilityList) {
      // Save under App > Fasilty > estateId > facilityId
      // DatabaseReference refFacility = FirebaseDatabase.instance
      //     .ref("App")
      //     .child("Fasilty")
      //     .child(estateId)
      //     .child(facility.id);
      // Save under App > Estate > Hottel > estateId > Fasilty > facilityId
      DatabaseReference refEstateFacility = FirebaseDatabase.instance
          .ref("App")
          .child("Estate")
          .child("Hottel")
          .child(estateId)
          .child("Fasilty")
          .child(facility.id);

      // await refFacility.set({
      //   "ID": facility.id,
      //   "Name": facility.name,
      //   "NameEn": facility.nameEn,
      //   "Price": facility.price,
      // });
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
        // Add to the list if checked
        selectedAdditionals.add(type);
      } else {
        // Remove from the list if unchecked
        selectedAdditionals.remove(type);
      }
    });
  }

  void _onSessionCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        // Add to the list if checked
        selectedSessions.add(type);
      } else {
        // Remove from the list if unchecked
        selectedSessions.remove(type);
      }
    });
  }

  void _onCheckboxChanged(bool value, String type) {
    setState(() {
      if (value) {
        // Add to the list if checked
        selectedEntries.add(type);
      } else {
        // Remove from the list if unchecked
        selectedEntries.remove(type);
      }
    });
  }

  // bool _areRequiredFieldsFilled() {
  //   return nameController.text.isNotEmpty &&
  //       enNameController.text.isNotEmpty &&
  //       // menuLinkController.text.isNotEmpty &&
  //       (countryValue != null && countryValue!.isNotEmpty) &&
  //       (stateValue != null && stateValue!.isNotEmpty) &&
  //       (cityValue != null && cityValue!.isNotEmpty);
  //
  //   // ((widget.userType == "3" && selectedRestaurantTypes.isNotEmpty) ||
  //   //     widget.userType !=
  //   //         "3") && // Ensure this condition applies only to restaurants
  //   // (widget.userType != "1"
  //   //     ? selectedSessions.isNotEmpty && selectedEntries.isNotEmpty
  //   //     : true) && // Ensure selectedSessions and selectedEntries are required only for userType != "1"
  //   // ((widget.userType == "1" && hasSwimmingPool) ||
  //   //     (widget.userType == "2" || widget.userType == "3"));
  //   // (facilityPdfUrl != null && facilityPdfUrl!.isNotEmpty) &&
  //   // (taxPdfUrl != null && taxPdfUrl!.isNotEmpty));
  // }
  bool _areRequiredFieldsFilled() {
    bool basicFieldsFilled = nameController.text.isNotEmpty &&
        enNameController.text.isNotEmpty &&
        enBranchController.text.isNotEmpty &&
        arBranchController.text.isNotEmpty &&
        (countryValue != null && countryValue!.isNotEmpty) &&
        (stateValue != null && stateValue!.isNotEmpty) &&
        (cityValue != null && cityValue!.isNotEmpty);

    // For hotels, ensure at least one room type is selected
    if (widget.userType == "1") {
      bool roomTypeSelected =
          single || double || suite || family || grandSuite || businessSuite;
      return basicFieldsFilled && roomTypeSelected;
    } else {
      return basicFieldsFilled;
    }
  }

  @override
  void initState() {
    super.initState();
    backendService.getIdEstate().then((id) {
      setState(() {
        idEstate = id;
      });
    });
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
                children: [
                  25.kH,
                  const ReusedProviderEstateContainer(
                    hint: "Information in Arabic",
                  ),
                  TextFormFieldStyle(
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
                  const ReusedProviderEstateContainer(
                    hint: "Information in English",
                  ),
                  TextFormFieldStyle(
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
                  40.kH,
                  const ReusedProviderEstateContainer(
                    hint: "Branch in English",
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Branch name (Required)",
                    icon: Icon(
                      Icons.location_on,
                      color: kDeepPurpleColor,
                    ),
                    control: enBranchController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.text,
                  ),
                  40.kH,
                  const ReusedProviderEstateContainer(
                    hint: "Branch in Arabic",
                  ),
                  TextFormFieldStyle(
                    context: context,
                    hint: "Branch name (Required)",
                    icon: Icon(
                      Icons.location_on,
                      color: kDeepPurpleColor,
                    ),
                    control: arBranchController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.text,
                  ),
                  40.kH,
                  Row(
                    children: [
                      const ReusedProviderEstateContainer(
                        hint: "Legal information",
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
                              FilePickerResult? result = await backendService
                                  .openSinglePdf(); // Open a single PDF picker
                              if (result != null &&
                                  result.files.single.path != null) {
                                String pdfPath = result.files.single.path!;
                                String? pdfUrl = await backendService
                                    .uploadFacilityPdfToStorage(
                                        pdfPath, idEstate.toString());

                                if (pdfUrl != null) {
                                  setState(() {
                                    facilityPdfUrl =
                                        pdfUrl; // Store the PDF URL
                                  });
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
                                // User canceled the picker
                                // Optionally, show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated(
                                        context, "No file selected")),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
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
                        // if (facilityPdfUrl != null &&
                        //     facilityPdfUrl!.isNotEmpty)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 10.0),
                        //     child: Text(
                        //       getTranslated(context, "PDF Uploaded"),
                        //       style: const TextStyle(
                        //         color: Colors.green,
                        //         fontSize: 14.0,
                        //       ),
                        //     ),
                        //   ),
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
                              // Display a preview of the PDF in a container (adjust height as needed)
                              Container(
                                height: 300,
                                child: PDF().cachedFromUrl(
                                  facilityPdfUrl!,
                                  placeholder: (progress) =>
                                      Center(child: Text('$progress %')),
                                  errorWidget: (error) =>
                                      Center(child: Text('Error loading PDF')),
                                ),
                              ),
                            ],
                          ),

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
                              FilePickerResult? result = await backendService
                                  .openSinglePdf(); // Open a single PDF picker
                              if (result != null &&
                                  result.files.single.path != null) {
                                String pdfPath = result.files.single.path!;
                                String? pdfUrl =
                                    await backendService.uploadTaxPdfToStorage(
                                        pdfPath, idEstate.toString());

                                if (pdfUrl != null) {
                                  setState(() {
                                    taxPdfUrl = pdfUrl; // Store the PDF URL
                                  });
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
                                // User canceled the picker
                                // Optionally, show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated(
                                        context, "No file selected")),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
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
                        // if (taxPdfUrl != null && taxPdfUrl!.isNotEmpty)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 10.0),
                        //     child: Text(
                        //       getTranslated(context, "PDF Uploaded"),
                        //       style: const TextStyle(
                        //         color: Colors.green,
                        //         fontSize: 14.0,
                        //       ),
                        //     ),
                        //   ),
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
                                  errorWidget: (error) =>
                                      Center(child: Text('Error loading PDF')),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // TextFormFieldStyle(
                  //   context: context,
                  //   hint: "Tax Number",
                  //   icon: Icon(
                  //     Icons.person,
                  //     color: kDeepPurpleColor,
                  //   ),
                  //   control: taxNumberController,
                  //   isObsecured: false,
                  //   validate: true,
                  //   textInputType: TextInputType.text,
                  // ),
                  40.kH,
                  const ReusedProviderEstateContainer(
                    hint: "Menu",
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
                  const ReusedProviderEstateContainer(
                    hint: "Phone number",
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
                  // Facility Section
                  Visibility(
                    visible: widget.userType == "1" ? true : false,
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
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: facilityNameArController,
                            decoration: InputDecoration(
                              labelText:
                                  getTranslated(context, "Service Name Ar"),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: facilityPriceController,
                            decoration: InputDecoration(
                              labelText:
                                  getTranslated(context, "Service Price"),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (facilityNameController.text.isNotEmpty &&
                                  facilityNameArController.text.isNotEmpty &&
                                  facilityPriceController.text.isNotEmpty) {
                                // Use a unique ID (here using timestamp)
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

                  // Visibility(
                  //   visible: widget.userType == "3" ? true : false,
                  //   child: Row(
                  //     children: [
                  //       const ReusedProviderEstateContainer(
                  //         hint: "Type of Restaurant",
                  //       ),
                  //       Container(
                  //         margin: const EdgeInsets.only(bottom: 20, top: 10),
                  //         child: Text(
                  //           getTranslated(context, "(Select at least 1)"),
                  //           style: const TextStyle(
                  //             fontWeight: FontWeight.bold,
                  //             fontSize: 10,
                  //             color: Colors.red,
                  //           ),
                  //         ),
                  //       )
                  //     ],
                  //   ),
                  // ),
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(
                  //     start: 30,
                  //   ),
                  //   padding: (const EdgeInsets.only(right: 25)),
                  //   child: RestaurantTypeVisibility(
                  //     isVisible: widget.userType == "3",
                  //     onCheckboxChanged: _onRestaurantTypeCheckboxChanged,
                  //     selectedRestaurantTypes:
                  //         selectedRestaurantTypes, // Pass the selected restaurant types list
                  //   ),
                  // ),
                  // 15.kH,
                  // Visibility(
                  //   visible: widget.userType == "3" || widget.userType == "2"
                  //       ? true
                  //       : false,
                  //   child: Row(
                  //     children: [
                  //       const ReusedProviderEstateContainer(
                  //         hint: "Entry allowed",
                  //       ),
                  //       Container(
                  //         margin: const EdgeInsets.only(bottom: 20, top: 10),
                  //         child: Text(
                  //           getTranslated(context, "(Select at least 1)"),
                  //           style: const TextStyle(
                  //             fontWeight: FontWeight.bold,
                  //             fontSize: 10,
                  //             color: Colors.red,
                  //           ),
                  //         ),
                  //       )
                  //     ],
                  //   ),
                  // ),
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(
                  //     start: 50,
                  //   ),
                  //   child: EntryVisibility(
                  //     isVisible:
                  //         widget.userType == "3" || widget.userType == "2",
                  //     onCheckboxChanged: _onCheckboxChanged,
                  //     selectedEntries:
                  //         selectedEntries, // Pass the list of selected entries
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: widget.userType == "3" || widget.userType == "2"
                  //       ? true
                  //       : false,
                  //   child: Row(
                  //     children: [
                  //       const ReusedProviderEstateContainer(
                  //         hint: 'Sessions type',
                  //       ),
                  //       Container(
                  //         margin: const EdgeInsets.only(bottom: 20, top: 10),
                  //         child: Text(
                  //           getTranslated(context, "(Select at least 1)"),
                  //           style: const TextStyle(
                  //             fontWeight: FontWeight.bold,
                  //             fontSize: 10,
                  //             color: Colors.red,
                  //           ),
                  //         ),
                  //       )
                  //     ],
                  //   ),
                  // ),
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(
                  //     start: 50,
                  //   ),
                  //   child: SessionsVisibility(
                  //     isVisible:
                  //         widget.userType == "3" || widget.userType == "2",
                  //     onCheckboxChanged: _onSessionCheckboxChanged,
                  //     selectedSessions:
                  //         selectedSessions, // Pass the selected sessions list
                  //   ),
                  // ),
                  // 40.kH,
                  // Visibility(
                  //   visible: widget.userType == "3" || widget.userType == "2"
                  //       ? true
                  //       : false,
                  //   child: const ReusedProviderEstateContainer(
                  //     hint: "Additionals",
                  //   ),
                  // ),
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(
                  //     start: 50,
                  //   ),
                  //   child: AdditionalsRestaurantCoffee(
                  //     isVisible:
                  //         widget.userType == "3" || widget.userType == "2",
                  //     onCheckboxChanged: _onAdditionalCheckboxChanged,
                  //     selectedAdditionals:
                  //         selectedAdditionals, // Pass the selected additionals list
                  //   ),
                  // ),
                  // 40.kH,
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(
                  //     start: 50,
                  //   ),
                  //   child: MusicVisibility(
                  //     isVisible:
                  //         widget.userType == "3" || widget.userType == "2",
                  //     checkMusic: checkMusic,
                  //     haveMusic: haveMusic,
                  //     haveSinger: haveSinger,
                  //     haveDJ: haveDJ,
                  //     haveOud: haveOud,
                  //     onMusicChanged: (value) {
                  //       setState(() {
                  //         checkMusic = value;
                  //         if (!checkMusic) {
                  //           haveMusic = false;
                  //           haveSinger = false;
                  //           haveDJ = false;
                  //           haveOud = false;
                  //         } else if (widget.userType == "2") {
                  //           haveMusic = true;
                  //         }
                  //       });
                  //     },
                  //     onSingerChanged: (value) {
                  //       setState(() {
                  //         haveSinger = value;
                  //         if (value) {
                  //           listMusic.add("singer");
                  //         } else {
                  //           listMusic.remove("singer");
                  //         }
                  //       });
                  //     },
                  //     onDJChanged: (value) {
                  //       setState(() {
                  //         haveDJ = value;
                  //         if (value) {
                  //           listMusic.add("DJ");
                  //         } else {
                  //           listMusic.remove("DJ");
                  //         }
                  //       });
                  //     },
                  //     onOudChanged: (value) {
                  //       setState(() {
                  //         haveOud = value;
                  //         if (value) {
                  //           listMusic.add("Oud");
                  //         } else {
                  //           listMusic.remove("Oud");
                  //         }
                  //       });
                  //     },
                  //   ),
                  // ),
                  // const ReusedProviderEstateContainer(
                  //   hint: "Valet Options",
                  // ),
                  // Container(
                  //   margin: const EdgeInsetsDirectional.only(start: 50),
                  //   child: Column(
                  //     children: [
                  //       CheckboxListTile(
                  //         title:
                  //             Text(getTranslated(context, "Is there valet?")),
                  //         value: hasValet,
                  //         onChanged: (bool? value) {
                  //           setState(() {
                  //             hasValet = value ?? false;
                  //             valetWithFees = false; // Reset valet fees option
                  //           });
                  //         },
                  //         activeColor: kPurpleColor,
                  //         controlAffinity: ListTileControlAffinity.leading,
                  //       ),
                  //       Visibility(
                  //         visible: hasValet,
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             CheckboxListTile(
                  //               title: Text(
                  //                   getTranslated(context, "Valet with fees")),
                  //               value: valetWithFees,
                  //               onChanged: (bool? value) {
                  //                 setState(() {
                  //                   valetWithFees = value ?? false;
                  //                 });
                  //               },
                  //               activeColor: kDeepPurpleColor,
                  //               controlAffinity:
                  //                   ListTileControlAffinity.leading,
                  //             ),
                  //             Visibility(
                  //               visible: !valetWithFees,
                  //               child: Padding(
                  //                 padding: const EdgeInsetsDirectional.only(
                  //                     start: 16.0),
                  //                 child: Text(
                  //                   getTranslated(context,
                  //                       "If valet with fees is not selected, valet service is free."),
                  //                   style: TextStyle(
                  //                     color: Colors.red,
                  //                     fontSize: 12.sp,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: widget.userType == "2" || widget.userType == "3",
                  //   child: const ReusedProviderEstateContainer(
                  //     hint: "Kids Area Options",
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: widget.userType == "2" || widget.userType == "3",
                  //   child: Container(
                  //     margin: const EdgeInsetsDirectional.only(start: 50),
                  //     child: Column(
                  //       children: [
                  //         CheckboxListTile(
                  //           title: Text(
                  //               getTranslated(context, "Is there Kids Area?")),
                  //           value: hasKidsArea,
                  //           onChanged: (bool? value) {
                  //             setState(() {
                  //               hasKidsArea = value ?? false;
                  //             });
                  //           },
                  //           activeColor: kDeepPurpleColor,
                  //           controlAffinity: ListTileControlAffinity.leading,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // const ReusedProviderEstateContainer(
                  //   hint: "Smoking Area?",
                  // ),
                  // Visibility(
                  //   visible: widget.userType == "2" || widget.userType == "3",
                  //   child: Container(
                  //     margin: const EdgeInsetsDirectional.only(start: 50),
                  //     child: Column(
                  //       children: [
                  //         CheckboxListTile(
                  //           title: Text(
                  //               getTranslated(context, "Is Smoking Allowed?")),
                  //           value: checkIsSmokingAllowed,
                  //           onChanged: (bool? value) {
                  //             setState(() {
                  //               checkIsSmokingAllowed = value ?? false;
                  //             });
                  //           },
                  //           activeColor: kDeepPurpleColor,
                  //           controlAffinity: ListTileControlAffinity.leading,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
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
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "1", // Show only for Hotels
                    child: const ReusedProviderEstateContainer(
                      hint: "Hotel Amenities",
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
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const ReusedProviderEstateContainer(
                    hint: "Location information",
                  ),
                  20.kH,
                  CustomCSCPicker(
                    key: const PageStorageKey('location_picker'),
                    onCountryChanged: (value) {
                      setState(() {
                        countryValue = value;
                      });
                    },
                    onStateChanged: (value) {
                      setState(() {
                        stateValue = value;
                      });
                    },
                    onCityChanged: (value) {
                      setState(() {
                        cityValue = value;
                      });
                    },
                  ),
                  40.kH,
                  Visibility(
                    visible: widget.userType == "1" ? true : false,
                    child: const ReusedProviderEstateContainer(
                        hint: "What We have ?"),
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
                        // Check if all required fields are filled
                        if (!_areRequiredFieldsFilled()) {
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
                          return; // Stop further execution if fields are incomplete
                        }

                        // Check if PDF has been uploaded
                        if (facilityPdfUrl == null || facilityPdfUrl!.isEmpty) {
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

                        // Show the custom loading dialog
                        showCustomLoadingDialog(context);

                        String childType = '';
                        String ID;

                        // Determine childType based on userType
                        if (widget.userType == "1") {
                          childType = "Hottel"; // Corrected typo
                        } else if (widget.userType == "2") {
                          childType = "Coffee";
                        } else {
                          childType = "Restaurant";
                        }

                        String music = checkMusic ? "1" : "0";

                        User? user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          String userID = user.uid;
                          print("The userId is $userID");

                          DatabaseReference userRef = FirebaseDatabase.instance
                              .ref('App')
                              .child('User')
                              .child(userID);
                          DataSnapshot snapshot = await userRef.get();
                          Map<String, dynamic> userDetails = {};

                          if (snapshot.exists && snapshot.value != null) {
                            userDetails = Map<String, dynamic>.from(
                                snapshot.value as Map);
                          }

                          String? firstName = userDetails["FirstName"];
                          String? lastName = userDetails["LastName"];
                          String? typeAccount = userDetails["TypeAccount"];
                          if (firstName == null ||
                              firstName.isEmpty ||
                              lastName == null ||
                              lastName.isEmpty) {
                            // Dismiss the loading dialog
                            Navigator.of(context).pop();

                            // Show an error message if first name or last name is missing
                            showDialog(
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
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog first

                                        // Navigate to PersonalInfoScreen with fetched user data
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
                                              // dateOfBirth:
                                              //     userDetails['DateOfBirth'] ??
                                              //         '',
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
                            return; // Stop further execution if names are missing
                          }

                          if (firstName != null && lastName != null) {
                            // Add room types if selected
                            if (single) listEntry.add("Single");
                            if (double) listEntry.add("Double");
                            if (suite) listEntry.add("Suite");
                            if (family) listEntry.add("Hotel Apartments");
                            if (grandSuite) listEntry.add('Grand Suite');
                            if (businessSuite) listEntry.add('Business Suite');

                            // Add estate with provided information
                            await backendService.addEstate(
                              childType: childType,
                              idEstate: idEstate.toString(),
                              nameAr: nameController.text,
                              nameEn: enNameController.text,
                              branchEn: enBranchController.text,
                              branchAr: arBranchController.text,
                              bioAr: bioController.text,
                              bioEn: enBioController.text,
                              country: countryValue ?? "",
                              city: cityValue ?? "",
                              state: stateValue ?? "",
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
                              isThereBreakfastLounge:
                                  checkIsThereBreakfastLounge,
                              isThereLaunchLounge: checkIsThereLaunchLounge,
                              isThereDinnerLounge: checkIsThereDinnerLounge,
                              facilityImageUrl: facilityPdfUrl ?? "",
                              taxImageUrl:
                                  taxPdfUrl ?? "", // Renamed for clarity
                              breakfastLoungePrice: breakfastPrice.isNotEmpty
                                  ? breakfastPrice
                                  : "0",
                              launchLoungePrice:
                                  launchPrice.isNotEmpty ? launchPrice : "0",
                              dinnerLoungePrice:
                                  dinnerPrice.isNotEmpty ? dinnerPrice : "0",
                            );

                            // Add individual rooms if selected
                            ID = idEstate.toString();
                            if (single) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "1",
                                roomName: "Single",
                                roomPrice: singleController.text,
                                roomBioAr: singleControllerBioAr.text,
                                roomBioEn: singleControllerBioEn.text,
                              );
                            }
                            if (double) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "2",
                                roomName: "Double",
                                roomPrice: doubleController.text,
                                roomBioAr: doubleControllerBioAr.text,
                                roomBioEn: doubleControllerBioEn.text,
                              );
                            }
                            if (suite) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "3",
                                roomName: "Suite",
                                roomPrice: suiteController.text,
                                roomBioAr: suiteControllerBioAr.text,
                                roomBioEn: suiteControllerBioEn.text,
                              );
                            }
                            if (family) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "4",
                                roomName: "Family",
                                roomPrice: familyController.text,
                                roomBioAr: familyControllerBioAr.text,
                                roomBioEn: familyControllerBioEn.text,
                              );
                            }
                            if (grandSuite) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "4",
                                roomName: "Grand Suite",
                                roomPrice: grandSuiteController.text,
                                roomBioAr: grandSuiteControllerBioAr.text,
                                roomBioEn: grandSuiteControllerBioEn.text,
                              );
                            }
                            if (businessSuite) {
                              await backendService.addRoom(
                                estateId: idEstate.toString(),
                                roomId: "4",
                                roomName: "Business Suite",
                                roomPrice: businessSuiteController.text,
                                roomBioAr: businessSuiteControllerBioAr.text,
                                roomBioEn: businessSuiteControllerBioEn.text,
                              );
                            }
                            await saveFacilities(idEstate.toString());
                            idEstate = (idEstate! + 1);
                            await backendService.updateEstateId(idEstate!);

                            // Dismiss the loading dialog
                            Navigator.of(context).pop();

                            // Navigate to MapsScreen after successful addition
                            // Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (context) => MapsScreen(
                            //       id: ID,
                            //       typeEstate: childType,
                            //     ),
                            //   ),
                            // );
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => MapsScreen(
                                      id: ID, typeEstate: childType)),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            // Dismiss the loading dialog
                            Navigator.of(context).pop();

                            setState(() {
                              btnLogin = Text('Failed to get User details');
                            });
                          }
                        } else {
                          // Dismiss the loading dialog
                          Navigator.of(context).pop();

                          setState(() {
                            btnLogin = Text('User not logged in');
                          });
                        }
                      })
                  // Removed the commented-out Align widget
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
