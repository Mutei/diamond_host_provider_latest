// Import necessary libraries

import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';
import '../services/local_notifications.dart';
import '../widgets/birthday_textform_field.dart';
import '../widgets/choose_city.dart';
import '../widgets/reused_elevated_button.dart';
import 'main_screen.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class PersonalInfoScreen extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final String password;
  final String typeUser;
  final String typeAccount;
  final String? firstName;
  final String? secondName;
  final String? lastName;
  // final String? dateOfBirth;
  final String? city;
  final String? country;
  final String? state;
  final String? restorationId;

  const PersonalInfoScreen(
      {super.key,
      required this.email,
      required this.phoneNumber,
      required this.password,
      required this.typeUser,
      required this.typeAccount,
      this.firstName,
      this.secondName,
      this.lastName,
      // this.dateOfBirth,
      this.city,
      this.restorationId,
      this.country,
      this.state});

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with RestorationMixin {
  final TextEditingController _firstNameController = TextEditingController();
  // final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bodController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  // String countryValue = '';
  // String? stateValue = "";
  // String? cityValue = "";
  bool validateSpecialDate = false;
  String? get restorationId => widget.restorationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with existing data
    _firstNameController.text = widget.firstName ?? '';
    // _secondNameController.text = widget.secondName ?? '';
    _lastNameController.text = widget.lastName ?? '';
    // _bodController.text = widget.dateOfBirth ?? '';
    // cityValue = widget.city ?? '';
    // countryValue = widget.country ?? '';
    // stateValue = widget.state ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    // _secondNameController.dispose();
    _lastNameController.dispose();
    _bodController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  String _trWithPlaceholders(
      BuildContext context, String key, Map<String, String> ph) {
    String s = getTranslated(context, key);
    ph.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  void _saveUserInfo() async {
    if (_firstNameController.text.isEmpty ||
            // _secondNameController.text.isEmpty ||
            _lastNameController.text.isEmpty
        // ||
        // countryValue.isEmpty ||
        // stateValue!.isEmpty ||
        // cityValue!.isEmpty
        ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final String userId = user.uid;

    // Fetch existing data so we don't wipe fields we didn’t edit
    final ref =
        FirebaseDatabase.instance.ref("App").child("User").child(userId);
    final snapshot = await ref.get();

    Map<String, dynamic> existingData = {};
    if (snapshot.exists && snapshot.value != null) {
      existingData = Map<String, dynamic>.from(snapshot.value as Map);
    }

    // final Map<String, String?> updatedUserData = {
    //   if (_firstNameController.text != existingData['FirstName'])
    //     'FirstName': _firstNameController.text,
    //   if (_secondNameController.text != existingData['SecondName'])
    //     'SecondName': _secondNameController.text,
    //   if (_lastNameController.text != existingData['LastName'])
    //     'LastName': _lastNameController.text,
    //   if (cityValue != existingData['City']) 'City': cityValue,
    //   if (stateValue != existingData['State']) 'State': stateValue,
    //   if (countryValue != existingData['Country']) 'Country': countryValue,
    //   'Email': widget.email,
    //   'PhoneNumber': widget.phoneNumber,
    //   'Password': widget.password,
    //   'TypeUser': widget.typeUser, // keep same as passed
    //   'TypeAccount': widget.typeAccount, // keep same as passed
    //   'userId': userId,
    //   'DateOfRegistration': existingData['DateOfRegistration'] ??
    //       DateFormat('dd/MM/yyyy').format(DateTime.now()),
    //   'AcceptedTermsAndConditions': 'true',
    // };
    final Map<String, dynamic> updatedUserData = {
      if (_firstNameController.text != (existingData['FirstName'] ?? ''))
        'FirstName': _firstNameController.text.trim(),
      // if (_secondNameController.text != (existingData['SecondName'] ?? ''))
      //   'SecondName': _secondNameController.text.trim(),
      if (_lastNameController.text != (existingData['LastName'] ?? ''))
        'LastName': _lastNameController.text.trim(),

      // if (cityValue != (existingData['City'] ?? '')) 'City': cityValue,
      // if (stateValue != (existingData['State'] ?? '')) 'State': stateValue,
      // if (countryValue != (existingData['Country'] ?? ''))
      //   'Country': countryValue,

      // keep required fields
      'Email': widget.email.trim().toLowerCase(),
      'PhoneNumber': widget.phoneNumber,
      'Password': widget.password,
      'TypeUser': widget.typeUser,
      'TypeAccount': widget.typeAccount,
      'userId': userId,
      'DateOfRegistration': existingData['DateOfRegistration'] ??
          DateFormat('dd/MM/yyyy').format(DateTime.now()),

      // ✅ important: keep it boolean (not "true" string)
      'AcceptedTermsAndConditions': true,

      // ✅ gate for MainScreen access (same as FillInfoScreen)
      'OnboardingCompleted': true,
    };

    await ref.update(updatedUserData);

    // ==== NEW: Welcome local notification (ONLY for real "users")
    // If your app defines TypeUser: '1' = Customer/User, '2' = Provider,
    // keep this guard to notify only customers:
    // PersonalInfoScreen::_saveUserInfo()
// Send welcome notification ONLY for providers
    if (widget.typeUser == '2') {
      final first = _firstNameController.text.trim();
      final last = _lastNameController.text.trim();
      final full = [first, last].where((s) => s.isNotEmpty).join(' ');
      final String title =
          _trWithPlaceholders(context, 'WelcomeName', {'{name}': full});
      final String body = getTranslated(context, 'WelcomeBody');

      await AppLocalNotifications.showWelcome(title: title, body: body);
    }

    // Save login status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("TypeUser", widget.typeUser);
    await prefs.setBool('isLoggedIn', true);

    // Navigate to MainScreen
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: kDeepPurpleColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.lightBlue[50],
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: DatePickerDialog(
            restorationId: 'date_picker_dialog',
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
            firstDate: DateTime(1900),
            lastDate: DateTime(2024),
          ),
        );
      },
    );
  }

  final RestorableDateTime _selectedDate =
      RestorableDateTime(DateTime(2021, 7, 25));
  late final RestorableRouteFuture<DateTime?>
      _restorableBODDatePickerRouteFuture = RestorableRouteFuture<DateTime?>(
    onComplete: _selectBirthOfDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableBODDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectBirthOfDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        _bodController.text =
            '${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
          title: getTranslated(context, "Fill up your Personal Information")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                    labelText: getTranslated(context, 'First Name')),
              ),
              // const SizedBox(height: 10),
              // TextField(
              //   controller: _secondNameController,
              //   decoration: InputDecoration(
              //       labelText: getTranslated(context, 'Second Name')),
              // ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                    labelText: getTranslated(context, 'Last Name')),
              ),
              const SizedBox(height: 10),
              // InkWell(
              //   child: TextFormFieldStyle(
              //     context: context,
              //     hint: "Birthday",
              //     icon: Icon(
              //       Icons.calendar_month,
              //       color: kDeepPurpleColor,
              //     ),
              //     control: _bodController,
              //     isObsecured: false,
              //     validate: validateSpecialDate,
              //     textInputType: TextInputType.text,
              //   ),
              //   onTap: () {
              //     _restorableBODDatePickerRouteFuture.present();
              //   },
              // ),
              // CustomCSCPicker(
              //   key: const PageStorageKey('location_picker'),
              //   onCountryChanged: (value) {
              //     setState(() {
              //       countryValue = value;
              //     });
              //   },
              //   onStateChanged: (value) {
              //     setState(() {
              //       stateValue = value;
              //     });
              //   },
              //   onCityChanged: (value) {
              //     setState(() {
              //       cityValue = value;
              //     });
              //   },
              // ),
              CustomButton(
                text: getTranslated(context, 'Save'),
                onPressed: _saveUserInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
