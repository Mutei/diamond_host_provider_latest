import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import 'package:daimond_host_provider/screens/request_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'all_posts_screen.dart';
import 'notification_screen.dart';
import 'upgrade_account_screen.dart';
import 'main_screen_content.dart';

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

  final List<Widget> _screens = [
    const MainScreenContent(),
    RequestScreen(),
    const AllPostsScreen(),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkPersonalInfo();
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
        bool isDateOfBirthMissing = dataUser['DateOfBirth'] == null ||
            dataUser['DateOfBirth'].toString().isEmpty;
        bool isCityMissing =
            dataUser['City'] == null || dataUser['City'].toString().isEmpty;
        bool isCountryMissing = dataUser['Country'] == null ||
            dataUser['Country'].toString().isEmpty;
        bool isStateMissing =
            dataUser['State'] == null || dataUser['State'].toString().isEmpty;

        if (isFirstNameMissing ||
            isSecondNameMissing ||
            isLastNameMissing ||
            isDateOfBirthMissing ||
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
              duration: Duration(seconds: 3),
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
                        dateOfBirth: dataUser['DateOfBirth'] ?? '',
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
