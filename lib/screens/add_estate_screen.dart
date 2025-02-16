import 'package:daimond_host_provider/backend/adding_estate_services.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/widgets/extra_services.dart';
import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../localization/language_constants.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/rooms.dart';
import '../widgets/birthday_textform_field.dart';
import '../widgets/choose_city.dart';
import '../widgets/entry_visibility.dart';
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

  TextEditingController enNameController = TextEditingController();
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
  late String? countryValue;
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

  bool _areRequiredFieldsFilled() {
    return nameController.text.isNotEmpty &&
        enNameController.text.isNotEmpty &&
        menuLinkController.text.isNotEmpty &&
        (countryValue != null && countryValue!.isNotEmpty) &&
        (stateValue != null && stateValue!.isNotEmpty) &&
        (cityValue != null && cityValue!.isNotEmpty) &&
        selectedRestaurantTypes.isNotEmpty &&
        selectedSessions.isNotEmpty &&
        selectedEntries
            .isNotEmpty && // Check if at least one restaurant type is selected
        ((widget.userType == "1" && hasSwimmingPool) ||
            (widget.userType == "2" || widget.userType == "3") &&
                (facilityPdfUrl != null && facilityPdfUrl!.isNotEmpty) &&
                (taxPdfUrl != null && taxPdfUrl!.isNotEmpty));
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
                      Icons.person,
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
                      Icons.person,
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
                      Icons.person,
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
                      Icons.person,
                      color: kDeepPurpleColor,
                    ),
                    control: enBioController,
                    isObsecured: false,
                    validate: true,
                    textInputType: TextInputType.text,
                  ),
                  40.kH,
                  const ReusedProviderEstateContainer(
                    hint: "Legal information",
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
                        if (facilityPdfUrl != null &&
                            facilityPdfUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              getTranslated(context, "PDF Uploaded"),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14.0,
                              ),
                            ),
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
                        if (taxPdfUrl != null && taxPdfUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              getTranslated(context, "PDF Uploaded"),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14.0,
                              ),
                            ),
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
                  80.kH,
                  Visibility(
                    visible: widget.userType == "3" ? true : false,
                    child: const ReusedProviderEstateContainer(
                      hint: "Type of Restaurant",
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
                      selectedRestaurantTypes:
                          selectedRestaurantTypes, // Pass the selected restaurant types list
                    ),
                  ),
                  15.kH,
                  Visibility(
                    visible: widget.userType == "3" || widget.userType == "2"
                        ? true
                        : false,
                    child: const ReusedProviderEstateContainer(
                      hint: "Entry allowed",
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
                      selectedEntries:
                          selectedEntries, // Pass the list of selected entries
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "3" || widget.userType == "2"
                        ? true
                        : false,
                    child: const ReusedProviderEstateContainer(
                      hint: 'Sessions type',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                      start: 50,
                    ),
                    child: SessionsVisibility(
                      isVisible:
                          widget.userType == "3" || widget.userType == "2",
                      onCheckboxChanged: _onSessionCheckboxChanged,
                      selectedSessions:
                          selectedSessions, // Pass the selected sessions list
                    ),
                  ),
                  40.kH,
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
                      selectedAdditionals:
                          selectedAdditionals, // Pass the selected additionals list
                    ),
                  ),
                  40.kH,
                  Container(
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
                  const ReusedProviderEstateContainer(
                    hint: "Valet Options",
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
                              valetWithFees = false; // Reset valet fees option
                            });
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
                  Visibility(
                    visible: widget.userType == "2" || widget.userType == "3",
                    child: const ReusedProviderEstateContainer(
                      hint: "Kids Area Options",
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
                            },
                            activeColor: kDeepPurpleColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.userType == "2" || widget.userType == "3",
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
                                    "Please upload the facility PDF before proceeding.",
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
                                    "Please upload the facility PDF before proceeding.",
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

                          Map<String, String?> userDetails =
                              await backendService.getUserDetails(userID);

                          String? firstName = userDetails["firstName"];
                          String? lastName = userDetails["lastName"];
                          String? typeAccount = userDetails["typeAccount"];

                          if (firstName != null && lastName != null) {
                            // Add room types if selected
                            if (single) listEntry.add("Single");
                            if (double) listEntry.add("Double");
                            if (suite) listEntry.add("Suite");
                            if (family) listEntry.add("Family");
                            if (grandSuite) listEntry.add('Grand Suite');
                            if (businessSuite) listEntry.add('Business Suite');

                            // Add estate with provided information
                            await backendService.addEstate(
                              childType: childType,
                              idEstate: idEstate.toString(),
                              nameAr: nameController.text,
                              nameEn: enNameController.text,
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
                              listEntry: selectedEntries,
                              price: singleController.text.isNotEmpty
                                  ? singleController.text
                                  : "150",
                              priceLast: familyController.text.isNotEmpty
                                  ? familyController.text
                                  : "1500",
                              ownerFirstName: firstName,
                              ownerLastName: lastName,
                              menuLink: menuLinkController.text,
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
                            idEstate = (idEstate! + 1);
                            await backendService.updateEstateId(idEstate!);

                            // Dismiss the loading dialog
                            Navigator.of(context).pop();

                            // Navigate to MapsScreen after successful addition
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MapsScreen(
                                  id: ID,
                                  typeEstate: childType,
                                ),
                              ),
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
