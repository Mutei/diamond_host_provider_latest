import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/edit_profile_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String secondName;
  final String lastName;

  const EditProfileScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.lastName,
    required this.secondName,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _secondNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isChanged = false;
  late String firstName;
  late String secondName;
  late String lastName;
  late String email;
  late String phoneNumber;
  late String country;
  late String city;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _secondNameController = TextEditingController(text: widget.secondName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _countryController = TextEditingController(text: widget.country);
    _cityController = TextEditingController(text: widget.city);

    _firstNameController.addListener(_onTextChanged);
    _secondNameController.addListener(_onTextChanged);
    _lastNameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _countryController.addListener(_onTextChanged);
    _cityController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isChanged = _firstNameController.text != widget.firstName ||
          _emailController.text != widget.email ||
          _phoneController.text != widget.phone ||
          _countryController.text != widget.country ||
          _cityController.text != widget.city ||
          _secondNameController.text != widget.secondName ||
          _lastNameController.text != widget.lastName;
    });
  }

  Future<void> saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('App')
            .child('User')
            .child(userId);

        await userRef.update({
          'FirstName': _firstNameController.text,
          'SecondName': _secondNameController.text,
          'LastName': _lastNameController.text,
          'Email': _emailController.text,
          'PhoneNumber': _phoneController.text,
          'Country': _countryController.text,
          'City': _cityController.text,
        });

        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          getTranslated(context, "Edit Profile"),
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isChanged ? () => saveProfileData() : null,
            style: TextButton.styleFrom(
              foregroundColor: _isChanged ? Colors.white : Colors.grey,
            ),
            child: Text(
              getTranslated(context, "Save"),
              style: TextStyle(
                color: _isChanged ? kDeepPurpleColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                EditScreenTextFormField(
                  controller: _firstNameController,
                  labelText: getTranslated(context, "First Name"),
                  onChanged: (value) {
                    firstName = value;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "First name must not be empty",
                      );
                    }
                    return null;
                  },
                ),
                EditScreenTextFormField(
                  controller: _secondNameController,
                  labelText: getTranslated(context, "Second Name"),
                  onChanged: (value) {
                    secondName = value;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Second name must not be empty",
                      );
                    }
                    return null;
                  },
                ),
                EditScreenTextFormField(
                  controller: _lastNameController,
                  labelText: getTranslated(context, "Last Name"),
                  onChanged: (value) {
                    lastName = value;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Last name must not be empty",
                      );
                    }
                    return null;
                  },
                ),
                EditScreenTextFormField(
                  controller: _emailController,
                  labelText: getTranslated(context, "Email"),
                  onChanged: (value) {
                    email = value;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Email must not be empty",
                      );
                    }
                    return null;
                  },
                ),
                // EditScreenTextFormField(
                //   controller: _phoneController,
                //   labelText: getTranslated(context, "Phone"),
                //   onChanged: (value) {
                //     phoneNumber = value;
                //   },
                //   validator: (value) {
                //     if (value!.isEmpty) {
                //       return getTranslated(
                //         context,
                //         "Phone Number must not be empty",
                //       );
                //     }
                //     return null;
                //   },
                // ),
                // EditScreenTextFormField(
                //   controller: _countryController,
                //   labelText: getTranslated(context, "*Country"),
                //   onChanged: (value) {
                //     country = value;
                //   },
                //   validator: (value) {
                //     if (value!.isEmpty) {
                //       return getTranslated(
                //         context,
                //         "Country must not be empty",
                //       );
                //     }
                //     return null;
                //   },
                // ),
                // EditScreenTextFormField(
                //   controller: _cityController,
                //   labelText: getTranslated(context, "*City"),
                //   onChanged: (value) {
                //     city = value;
                //   },
                //   validator: (value) {
                //     if (value!.isEmpty) {
                //       return getTranslated(
                //         context,
                //         "City must not be empty",
                //       );
                //     }
                //     return null;
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
