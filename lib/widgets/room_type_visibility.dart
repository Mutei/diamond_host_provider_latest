import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/widgets/reused_provider_estate_container.dart';
import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import 'birthday_textform_field.dart';

class RoomTypeVisibility extends StatefulWidget {
  final String userType;
  final bool single;
  final bool double;
  final bool suite;
  final bool family;
  final bool grandSuite;
  final bool businessSuite;
  final TextEditingController singleHotelRoomController;
  final TextEditingController doubleHotelRoomController;
  final TextEditingController suiteHotelRoomController;
  final TextEditingController familyHotelRoomController;
  final TextEditingController grandSuiteController;
  final TextEditingController grandSuiteControllerAr;
  final TextEditingController businessSuiteController;
  final TextEditingController businessSuiteControllerAr;
  final TextEditingController singleHotelRoomControllerBioAr;
  final TextEditingController singleHotelRoomControllerBioEn;
  final TextEditingController doubleHotelRoomControllerBioEn;
  final TextEditingController doubleHotelRoomControllerBioAr;
  final TextEditingController suiteHotelRoomControllerBioEn;
  final TextEditingController suiteHotelRoomControllerBioAr;
  final TextEditingController familyHotelRoomControllerBioAr;
  final TextEditingController familyHotelRoomControllerBioEn;
  final TextEditingController businessSuiteControllerBioEn;
  final TextEditingController businessSuiteControllerBioAr;
  final TextEditingController grandSuiteControllerBioEn;
  final TextEditingController grandSuiteControllerBioAr;
  final Function(bool) onSingleChanged;
  final Function(bool) onDoubleChanged;
  final Function(bool) onSuiteChanged;
  final Function(bool) onFamilyChanged;
  final Function(bool) onGrandChanged;
  final Function(bool) onBusinessChanged;
  final Function(bool, String) onCheckboxChanged;
  final Function(String) onBreakfastPriceChanged;
  final Function(String) onLaunchPriceChanged;
  final Function(String) onDinnerPriceChanged;

  const RoomTypeVisibility({
    super.key,
    required this.userType,
    required this.grandSuiteController,
    required this.businessSuiteControllerBioEn,
    required this.businessSuiteControllerBioAr,
    required this.grandSuiteControllerBioEn,
    required this.grandSuiteControllerBioAr,
    required this.grandSuiteControllerAr,
    required this.businessSuiteControllerAr,
    required this.businessSuiteController,
    required this.onBreakfastPriceChanged,
    required this.onLaunchPriceChanged,
    required this.onDinnerPriceChanged,
    required this.single,
    required this.double,
    required this.suite,
    required this.family,
    required this.businessSuite,
    required this.grandSuite,
    required this.singleHotelRoomController,
    required this.doubleHotelRoomController,
    required this.suiteHotelRoomController,
    required this.familyHotelRoomController,
    required this.singleHotelRoomControllerBioAr,
    required this.singleHotelRoomControllerBioEn,
    required this.doubleHotelRoomControllerBioEn,
    required this.doubleHotelRoomControllerBioAr,
    required this.suiteHotelRoomControllerBioEn,
    required this.suiteHotelRoomControllerBioAr,
    required this.familyHotelRoomControllerBioAr,
    required this.familyHotelRoomControllerBioEn,
    required this.onSingleChanged,
    required this.onDoubleChanged,
    required this.onSuiteChanged,
    required this.onFamilyChanged,
    required this.onCheckboxChanged,
    required this.onBusinessChanged,
    required this.onGrandChanged,
  });

  @override
  _RoomTypeVisibilityState createState() => _RoomTypeVisibilityState();
}

class _RoomTypeVisibilityState extends State<RoomTypeVisibility> {
  // Maps to store individual state for each room type
  Map<String, bool> checkIsSmokingAllowed = {};
  Map<String, bool> checkIsThereLounge = {};
  Map<String, bool> checkIsThereBreakfastLounge = {};
  Map<String, bool> checkIsThereLaunchLounge = {};
  Map<String, bool> checkIsThereDinnerLounge = {};
  Map<String, bool> showLoungeNote = {};

  // Maps to store individual TextEditingController for each room type's lounge prices
  Map<String, TextEditingController> breakfastPriceController = {};
  Map<String, TextEditingController> launchPriceController = {};
  Map<String, TextEditingController> dinnerPriceController = {};

  @override
  void dispose() {
    // Dispose of each TextEditingController created
    for (var controller in breakfastPriceController.values) {
      controller.dispose();
    }
    for (var controller in launchPriceController.values) {
      controller.dispose();
    }
    for (var controller in dinnerPriceController.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeRoomState(String roomType) {
    // Initialize each state variable for the room type only if not already initialized
    checkIsSmokingAllowed.putIfAbsent(roomType, () => false);
    checkIsThereLounge.putIfAbsent(roomType, () => false);
    checkIsThereBreakfastLounge.putIfAbsent(roomType, () => false);
    checkIsThereLaunchLounge.putIfAbsent(roomType, () => false);
    checkIsThereDinnerLounge.putIfAbsent(roomType, () => false);
    showLoungeNote.putIfAbsent(roomType, () => false);

    // Initialize TextEditingControllers for each room type's lounge prices
    breakfastPriceController.putIfAbsent(
        roomType, () => TextEditingController());
    launchPriceController.putIfAbsent(roomType, () => TextEditingController());
    dinnerPriceController.putIfAbsent(roomType, () => TextEditingController());
  }

  void _updateLoungeNote(String roomType) {
    setState(() {
      showLoungeNote[roomType] = !(checkIsThereBreakfastLounge[roomType]! ||
          checkIsThereLaunchLounge[roomType]! ||
          checkIsThereDinnerLounge[roomType]!);
    });
  }

  // Map to store room lounge prices for saving to Firebase
  Map<String, String> getRoomLoungePrices() {
    return {
      "singleRoomBreakfastLoungePrice":
          breakfastPriceController["Single"]?.text ?? "0",
      "singleRoomLaunchLoungePrice":
          launchPriceController["Single"]?.text ?? "0",
      "singleRoomDinnerLoungePrice":
          dinnerPriceController["Single"]?.text ?? "0",
      "doubleRoomBreakfastLoungePrice":
          breakfastPriceController["Double"]?.text ?? "0",
      "doubleRoomLaunchLoungePrice":
          launchPriceController["Double"]?.text ?? "0",
      "doubleRoomDinnerLoungePrice":
          dinnerPriceController["Double"]?.text ?? "0",
      "suiteRoomBreakfastLoungePrice":
          breakfastPriceController["Suite"]?.text ?? "0",
      "suiteRoomLaunchLoungePrice": launchPriceController["Suite"]?.text ?? "0",
      "suiteRoomDinnerLoungePrice": dinnerPriceController["Suite"]?.text ?? "0",
      "familyRoomBreakfastLoungePrice":
          breakfastPriceController["Hotel Apartments"]?.text ?? "0",
      "familyRoomLaunchLoungePrice":
          launchPriceController["Hotel Apartments"]?.text ?? "0",
      "familyRoomDinnerLoungePrice":
          dinnerPriceController["Hotel Apartments"]?.text ?? "0",
      "grandSuiteRoomBreakfastLoungePrice":
          breakfastPriceController["Grand Suite"]?.text ?? "0",
      "grandSuiteRoomLaunchLoungePrice":
          launchPriceController["Grand Suite"]?.text ?? "0",
      "grandSuiteRoomDinnerLoungePrice":
          dinnerPriceController["Grand Suite"]?.text ?? "0",
      "businessSuiteRoomBreakfastLoungePrice":
          breakfastPriceController["Business Suite"]?.text ?? "0",
      "businessSuiteRoomLaunchLoungePrice":
          launchPriceController["Business Suite"]?.text ?? "0",
      "businessSuiteRoomDinnerLoungePrice":
          dinnerPriceController["Business Suite"]?.text ?? "0",
    };
  }

  Map<String, String> getRoomLoungeOptions() {
    return {
      "singleRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Single"] ?? false) ? "1" : "0",
      "singleRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Single"] ?? false) ? "1" : "0",
      "singleRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Single"] ?? false) ? "1" : "0",
      "doubleRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Double"] ?? false) ? "1" : "0",
      "doubleRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Double"] ?? false) ? "1" : "0",
      "doubleRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Double"] ?? false) ? "1" : "0",
      "suiteRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Suite"] ?? false) ? "1" : "0",
      "suiteRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Suite"] ?? false) ? "1" : "0",
      "suiteRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Suite"] ?? false) ? "1" : "0",
      "familyRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Hotel Apartments"] ?? false)
              ? "1"
              : "0",
      "familyRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Hotel Apartments"] ?? false) ? "1" : "0",
      "familyRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Hotel Apartments"] ?? false) ? "1" : "0",
      "grandSuiteRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Grand Suite"] ?? false) ? "1" : "0",
      "grandSuiteRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Grand Suite"] ?? false) ? "1" : "0",
      "grandSuiteRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Grand Suite"] ?? false) ? "1" : "0",
      "businessSuiteRoomHasBreakfastLounge":
          (checkIsThereBreakfastLounge["Business Suite"] ?? false) ? "1" : "0",
      "businessSuiteRoomHasLaunchLounge":
          (checkIsThereLaunchLounge["Business Suite"] ?? false) ? "1" : "0",
      "businessSuiteRoomHasDinnerLounge":
          (checkIsThereDinnerLounge["Business Suite"] ?? false) ? "1" : "0",
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userType != "1") return Container();

    return Column(
      children: [
        _buildRoomType(
          context,
          'Single',
          widget.single,
          widget.singleHotelRoomController,
          widget.singleHotelRoomControllerBioAr,
          widget.singleHotelRoomControllerBioEn,
          widget.onSingleChanged,
        ),
        _buildRoomType(
          context,
          'Double',
          widget.double,
          widget.doubleHotelRoomController,
          widget.doubleHotelRoomControllerBioAr,
          widget.doubleHotelRoomControllerBioEn,
          widget.onDoubleChanged,
        ),
        _buildRoomType(
          context,
          'Suite',
          widget.suite,
          widget.suiteHotelRoomController,
          widget.suiteHotelRoomControllerBioAr,
          widget.suiteHotelRoomControllerBioEn,
          widget.onSuiteChanged,
        ),
        _buildRoomType(
          context,
          'Hotel Apartments',
          widget.family,
          widget.familyHotelRoomController,
          widget.familyHotelRoomControllerBioAr,
          widget.familyHotelRoomControllerBioEn,
          widget.onFamilyChanged,
        ),
        _buildRoomType(
          context,
          "Grand Suite",
          widget.grandSuite,
          widget.grandSuiteController,
          widget.grandSuiteControllerBioAr,
          widget.grandSuiteControllerBioEn,
          widget.onGrandChanged,
        ),
        _buildRoomType(
          context,
          "Business Suite",
          widget.businessSuite,
          widget.businessSuiteController,
          widget.businessSuiteControllerBioAr,
          widget.businessSuiteControllerBioEn,
          widget.onBusinessChanged,
        ),
      ],
    );
  }

// Additional widget-building methods like _buildRoomType, _buildCheckboxRow, _buildLoungePriceField, etc.
  Widget _buildRoomType(
    BuildContext context,
    String type,
    bool visible,
    TextEditingController controller,
    TextEditingController bioArController,
    TextEditingController bioEnController,
    Function(bool) onChanged,
  ) {
    _initializeRoomState(type);

    return Column(
      children: [
        Visibility(
          visible: !visible,
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, type),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Checkbox(
                  checkColor: Colors.white,
                  value: visible,
                  onChanged: (bool? value) => onChanged(value!),
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: visible,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusedProviderEstateContainer(
                        hint: type,
                      ),
                      TextFormFieldStyle(
                        context: context,
                        hint: "BioEn",
                        icon: Icon(
                          Icons.single_bed,
                          color: kDeepPurpleColor,
                        ),
                        control: bioEnController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.text,
                      ),
                      TextFormFieldStyle(
                        context: context,
                        hint: "BioAr",
                        icon: Icon(
                          Icons.description,
                          color: kDeepPurpleColor,
                        ),
                        control: bioArController,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.text,
                      ),
                      TextFormFieldStyle(
                        context: context,
                        hint: "Price",
                        icon: Icon(
                          Icons.description,
                          color: kDeepPurpleColor,
                        ),
                        control: controller,
                        isObsecured: false,
                        validate: true,
                        textInputType: TextInputType.phone,
                      ),
                      _buildCheckboxRow(
                        context,
                        "Is smoking allowed in the room?",
                        checkIsSmokingAllowed[type]!,
                        (value) {
                          setState(() => checkIsSmokingAllowed[type] = value);
                          widget.onCheckboxChanged(value, "IsSmokingAllowed");
                        },
                      ),
                      _buildCheckboxRow(
                        context,
                        "Is there a Lounge?",
                        checkIsThereLounge[type]!,
                        (value) {
                          setState(() {
                            checkIsThereLounge[type] = value;
                            if (!checkIsThereLounge[type]!) {
                              checkIsThereBreakfastLounge[type] = false;
                              checkIsThereLaunchLounge[type] = false;
                              checkIsThereDinnerLounge[type] = false;
                              showLoungeNote[type] = false;
                            }
                          });
                          widget.onCheckboxChanged(value, "IsThereLounge");
                        },
                      ),
                      if (checkIsThereLounge[type]!) ...[
                        _buildCheckboxRow(
                          context,
                          "Is there a breakfast Lounge?",
                          checkIsThereBreakfastLounge[type]!,
                          (value) {
                            setState(() {
                              checkIsThereBreakfastLounge[type] = value;
                              _updateLoungeNote(type);
                            });
                            widget.onCheckboxChanged(
                                value, "IsThereBreakfastLounge");
                          },
                        ),
                        if (checkIsThereBreakfastLounge[type]!)
                          _buildLoungePriceField(
                            context,
                            controller: breakfastPriceController[type]!,
                            hint: getTranslated(
                                context, "Breakfast Lounge Price"),
                            onChanged: widget.onBreakfastPriceChanged,
                          ),
                        _buildCheckboxRow(
                          context,
                          "Is there a launch Lounge?",
                          checkIsThereLaunchLounge[type]!,
                          (value) {
                            setState(() {
                              checkIsThereLaunchLounge[type] = value;
                              _updateLoungeNote(type);
                            });
                            widget.onCheckboxChanged(
                                value, "IsThereLaunchLounge");
                          },
                        ),
                        if (checkIsThereLaunchLounge[type]!)
                          _buildLoungePriceField(
                            context,
                            controller: launchPriceController[type]!,
                            hint: getTranslated(context, "Launch Lounge Price"),
                            onChanged: widget.onLaunchPriceChanged,
                          ),
                        _buildCheckboxRow(
                          context,
                          "Is there a dinner Lounge?",
                          checkIsThereDinnerLounge[type]!,
                          (value) {
                            setState(() {
                              checkIsThereDinnerLounge[type] = value;
                              _updateLoungeNote(type);
                            });
                            widget.onCheckboxChanged(
                                value, "IsThereDinnerLounge");
                          },
                        ),
                        if (checkIsThereDinnerLounge[type]!)
                          _buildLoungePriceField(
                            context,
                            controller: dinnerPriceController[type]!,
                            hint: getTranslated(context, "Dinner Lounge Price"),
                            onChanged: widget.onDinnerPriceChanged,
                          ),
                        if (showLoungeNote[type]!)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 5),
                            child: Text(
                              "Please select at least one Lounge option.",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Clear the information for this room type and close it
                    _clearRoomTypeState(type, onChanged);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearRoomTypeState(String type, Function(bool) onChanged) {
    setState(() {
      // Clear the checkboxes
      checkIsSmokingAllowed[type] = false;
      checkIsThereLounge[type] = false;
      checkIsThereBreakfastLounge[type] = false;
      checkIsThereLaunchLounge[type] = false;
      checkIsThereDinnerLounge[type] = false;
      showLoungeNote[type] = false;

      // Clear the TextEditingController values
      breakfastPriceController[type]?.clear();
      launchPriceController[type]?.clear();
      dinnerPriceController[type]?.clear();

      // Clear other room type controllers
      if (type == "Single") {
        widget.singleHotelRoomController.clear();
        widget.singleHotelRoomControllerBioAr.clear();
        widget.singleHotelRoomControllerBioEn.clear();
      } else if (type == "Double") {
        widget.doubleHotelRoomController.clear();
        widget.doubleHotelRoomControllerBioAr.clear();
        widget.doubleHotelRoomControllerBioEn.clear();
      } else if (type == "Suite") {
        widget.suiteHotelRoomController.clear();
        widget.suiteHotelRoomControllerBioAr.clear();
        widget.suiteHotelRoomControllerBioEn.clear();
      } else if (type == "Hotel Apartments") {
        widget.familyHotelRoomController.clear();
        widget.familyHotelRoomControllerBioAr.clear();
        widget.familyHotelRoomControllerBioEn.clear();
      } else if (type == "Grand Suite") {
        widget.grandSuiteController.clear();
        widget.grandSuiteControllerBioAr.clear();
        widget.grandSuiteControllerBioEn.clear();
      } else if (type == "Business Suite") {
        widget.businessSuiteController.clear();
        widget.businessSuiteControllerBioAr.clear();
        widget.businessSuiteControllerBioEn.clear();
      }

      // Close the room type by setting its visibility to false
      onChanged(false);
    });
  }

  Widget _buildLoungePriceField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCheckboxRow(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            getTranslated(context, label),
          ),
        ),
        Expanded(
          child: Checkbox(
            checkColor: Colors.white,
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue!),
            activeColor: kPurpleColor,
          ),
        ),
      ],
    );
  }
}
