import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/language_constants.dart';
import '../widgets/choose_city.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_elevated_button.dart';
import 'main_screen.dart';

// 👇 add this
import '../services/local_notifications.dart';

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

  // same helper you used in personal_info_screen
  String _trWithPlaceholders(
      BuildContext context, String key, Map<String, String> ph) {
    String s = getTranslated(context, key);
    ph.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Fill up your Personal Information"),
      ),
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
              const SizedBox(height: 16),
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
      debugPrint("Current user: ${currentUser?.uid}");

      if (currentUser != null) {
        final uid = currentUser.uid;
        final userRef = _db.child('App/User/$uid');

        // 1) save the info
        await userRef.update({
          'FirstName': _firstNameController.text.trim(),
          'SecondName': _secondNameController.text.trim(),
          'LastName': _lastNameController.text.trim(),
          'Gender': _gender,
          'Country': countryValue,
          'State': stateValue,
          'City': cityValue,
        });

        // 2) read TypeUser to apply the SAME condition as personal_info_screen
        final snap = await userRef.get();
        String? typeUser;
        if (snap.exists && snap.value is Map) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          typeUser = data['TypeUser']?.toString();
        }

        // 3) if provider -> send welcome local notification
        if (typeUser == '2') {
          final first = _firstNameController.text.trim();
          final last = _lastNameController.text.trim();
          final full = [first, last].where((s) => s.isNotEmpty).join(' ');

          final String title =
              _trWithPlaceholders(context, 'WelcomeName', {'{name}': full});
          final String body = getTranslated(context, 'WelcomeBody');

          await AppLocalNotifications.showWelcome(
            title: title,
            body: body,
          );
        }

        debugPrint("User info saved successfully, navigating to MainScreen");

        // 4) navigate to main
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        debugPrint("User not authenticated, cannot save info");
      }
    } else {
      debugPrint("Form validation failed");
    }
  }
}
