import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/language_constants.dart';
import '../widgets/choose_city.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_elevated_button.dart';
import 'main_screen.dart';

class FillInfoScreen extends StatefulWidget {
  const FillInfoScreen({super.key});

  @override
  _FillInfoScreenState createState() => _FillInfoScreenState();
}

class _FillInfoScreenState extends State<FillInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String countryValue = '';
  String? stateValue = "";
  String? cityValue = "";
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _gender;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
          title: getTranslated(context, "Fill up your Personal Information")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _secondNameController,
                decoration: const InputDecoration(labelText: 'Second Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your second name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
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
                onPressed: saveUserInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = _auth.currentUser;
      print("Current user: ${currentUser?.uid}");

      if (currentUser != null) {
        await _db.child('App/User/${currentUser.uid}').update({
          'FirstName': _firstNameController.text.trim(),
          'SecondName': _secondNameController.text.trim(),
          'LastName': _lastNameController.text.trim(),
          'Gender': _gender,
          'Country': countryValue,
          'State': stateValue,
          'City': cityValue,
        });

        print("User info saved successfully, navigating to MainScreen");

        // Navigate to MainScreen after saving info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        print("User not authenticated, cannot save info");
      }
    } else {
      print("Form validation failed");
    }
  }
}
