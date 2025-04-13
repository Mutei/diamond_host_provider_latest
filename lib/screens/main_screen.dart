import 'dart:async';

import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import 'package:daimond_host_provider/screens/request_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'all_posts_screen.dart';
import 'notification_screen.dart';
import 'upgrade_account_screen.dart';
import 'main_screen_content.dart';
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isPersonalInfoMissing = false;
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> dataUser = {};

  // Token listener variables for single-device login
  String? currentDeviceToken;
  late DatabaseReference tokenRef;
  StreamSubscription<DatabaseEvent>? tokenSubscription;
  Timer? _logoutTimer; // Timer for auto-sign out

  final List<Widget> _screens = [
    const MainScreenContent(),
    RequestScreen(),
    const AllPostsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    checkPersonalInfo();
    _initializeTokenListener();
    // Show alert dialog for new booking request after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GeneralProvider>(context, listen: false);
      if (provider.newRequestCount > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(getTranslated(context, "New Booking Request")),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(getTranslated(context, "You have")),
                Text(
                  " ${provider.newRequestCount.toString()} ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(getTranslated(context, "new booking request(s).")),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(getTranslated(context, "OK")),
              )
            ],
          ),
        );
      }
    });
  }

  // Initialize token listener to enforce single-device login
  Future<void> _initializeTokenListener() async {
    // Get current device's FCM token
    currentDeviceToken = await FirebaseMessaging.instance.getToken();

    // Set up a listener on the user's token in the database
    String uid = FirebaseAuth.instance.currentUser!.uid;
    tokenRef = FirebaseDatabase.instance.ref("App/User/$uid/Token");
    tokenSubscription = tokenRef.onValue.listen((DatabaseEvent event) {
      final remoteToken = event.snapshot.value as String?;
      if (remoteToken != null &&
          currentDeviceToken != null &&
          remoteToken != currentDeviceToken) {
        _handleTokenMismatch();
      }
    });
  }

  // Handle token mismatch by alerting the user and signing them out
  void _handleTokenMismatch() {
    // If already scheduled, do nothing
    if (_logoutTimer != null) return;

    // Start a timer that will sign out the user after 5 seconds if no interaction
    _logoutTimer = Timer(const Duration(seconds: 5), () {
      _signOut();
    });

    showDialog(
      context: context,
      barrierDismissible: false, // force user acknowledgment
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Session Ended")),
          content: Text(getTranslated(context,
              "Your account has been logged in from another device. This session will be closed.")),
          actions: [
            TextButton(
              onPressed: () {
                _logoutTimer?.cancel();
                _logoutTimer = null;
                Navigator.of(context).pop();
                _signOut();
              },
              child: Text(getTranslated(context, "OK")),
            )
          ],
        );
      },
    );
  }

  // Sign the user out and navigate back to the login screen
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    tokenSubscription?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  Future<void> checkPersonalInfo() async {
    try {
      // Fetch user data from Firebase
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('App').child('User').child(userId);
      print("Fetching data for user: $userId");

      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        dataUser = Map<String, dynamic>.from(snapshot.value as Map);
        print("Data fetched successfully: $dataUser");

        // Check if personal info fields are missing or empty
        bool isFirstNameMissing = dataUser['FirstName'] == null ||
            dataUser['FirstName'].toString().isEmpty;
        bool isSecondNameMissing = dataUser['SecondName'] == null ||
            dataUser['SecondName'].toString().isEmpty;
        bool isLastNameMissing = dataUser['LastName'] == null ||
            dataUser['LastName'].toString().isEmpty;
        bool isCityMissing =
            dataUser['City'] == null || dataUser['City'].toString().isEmpty;
        bool isCountryMissing = dataUser['Country'] == null ||
            dataUser['Country'].toString().isEmpty;
        bool isStateMissing =
            dataUser['State'] == null || dataUser['State'].toString().isEmpty;

        if (isFirstNameMissing ||
            isSecondNameMissing ||
            isLastNameMissing ||
            isCityMissing ||
            isStateMissing ||
            isCountryMissing) {
          setState(() {
            isPersonalInfoMissing = true;
          });

          // Show snackbar before alert dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Your personal information is incomplete. Please fill out the required fields."),
              duration: const Duration(seconds: 3),
            ),
          );

          // Show alert dialog
          showAlertDialog();
        } else {
          print("All personal info fields are complete.");
        }
      } else {
        print("No data found for the user.");
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  void showAlertDialog() {
    print("Showing alert dialog for incomplete profile.");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Incomplete Profile"),
          content: const Text(
              "Your personal information is incomplete. Please fill out the required fields."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonalInfoScreen(
                        email: dataUser['Email'] ?? '',
                        phoneNumber: dataUser['PhoneNumber'] ?? '',
                        password: dataUser['Password'] ?? '',
                        typeUser: dataUser['TypeUser'] ?? '',
                        typeAccount: dataUser['TypeAccount'] ?? '',
                        firstName: dataUser['FirstName'] ?? '',
                        secondName: dataUser['SecondName'] ?? '',
                        lastName: dataUser['LastName'] ?? '',
                        city: dataUser['City'] ?? '',
                        country: dataUser['Country'] ?? '',
                        state: dataUser['State'] ?? ''),
                  ),
                );
              },
              child: const Text("Update Info"),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
