// Import necessary libraries

import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';
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
  final String? dateOfBirth;
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
      this.dateOfBirth,
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
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bodController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  String countryValue = '';
  String? stateValue = "";
  String? cityValue = "";
  bool validateSpecialDate = false;
  String? get restorationId => widget.restorationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedGender = '';
  String _isSmoker = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with existing data
    _firstNameController.text = widget.firstName ?? '';
    _secondNameController.text = widget.secondName ?? '';
    _lastNameController.text = widget.lastName ?? '';
    _bodController.text = widget.dateOfBirth ?? '';
    cityValue = widget.city ?? '';
    countryValue = widget.country ?? '';
    stateValue = widget.state ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    _bodController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveUserInfo() async {
    if (_firstNameController.text.isEmpty ||
        _secondNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        countryValue.isEmpty ||
        stateValue!.isEmpty ||
        cityValue!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Fetch existing data to retain values like 'AcceptedTermsAndConditions'
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("App").child("User").child(userId);
      DataSnapshot snapshot = await ref.get();

      Map<String, dynamic> existingData = {};

      // Check if snapshot exists and is in the correct map format
      if (snapshot.exists && snapshot.value != null) {
        existingData = Map<String, dynamic>.from(
            snapshot.value as Map); // Cast to Map<String, dynamic>
      }

      // Prepare the new data (only the fields that we want to update)
      final Map<String, String?> updatedUserData = {
        if (_firstNameController.text != existingData['FirstName'])
          'FirstName': _firstNameController.text,
        if (_secondNameController.text != existingData['SecondName'])
          'SecondName': _secondNameController.text,
        if (_lastNameController.text != existingData['LastName'])
          'LastName': _lastNameController.text,
        if (_bodController.text != existingData['DateOfBirth'])
          'DateOfBirth': _bodController.text,
        if (cityValue != existingData['City']) 'City': cityValue,
        if (stateValue != existingData['State']) 'State': stateValue,
        if (countryValue != existingData['Country']) 'Country': countryValue,
        'Email': widget.email, // Keep the same
        'PhoneNumber': widget.phoneNumber, // Keep the same
        'Password': widget.password, // Keep the same
        'TypeUser': '2', // Keep the same
        'TypeAccount': widget.typeAccount, // Keep the same
        'userId': userId, // Keep the same
        'DateOfRegistration': existingData['DateOfRegistration'] ??
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'AcceptedTermsAndConditions': 'true',
      };

      // Use the update method to only change the specified fields
      await ref.update(updatedUserData);

      // Save the login status
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("TypeUser", widget.typeUser);
      await prefs.setBool('isLoggedIn', true);

      // Navigate to the MainScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    }
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
              const SizedBox(height: 10),
              TextField(
                controller: _secondNameController,
                decoration: InputDecoration(
                    labelText: getTranslated(context, 'Second Name')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                    labelText: getTranslated(context, 'Last Name')),
              ),
              const SizedBox(height: 10),
              InkWell(
                child: TextFormFieldStyle(
                  context: context,
                  hint: "Birthday",
                  icon: Icon(
                    Icons.calendar_month,
                    color: kDeepPurpleColor,
                  ),
                  control: _bodController,
                  isObsecured: false,
                  validate: validateSpecialDate,
                  textInputType: TextInputType.text,
                ),
                onTap: () {
                  _restorableBODDatePickerRouteFuture.present();
                },
              ),
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
