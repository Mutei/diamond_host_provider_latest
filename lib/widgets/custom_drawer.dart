import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/screens/profile_screen.dart';
import 'package:daimond_host_provider/screens/request_screen.dart';
import 'package:daimond_host_provider/screens/upgrade_account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/log_out_method.dart';
import '../constants/colors.dart';
import '../screens/all_posts_screen.dart';
import '../screens/provider_notification_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/type_estate_screen.dart';
import '../state_management/general_provider.dart';
import '../utils/global_methods.dart';
import 'item_drawer.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_database/firebase_database.dart';
import '../animations_widgets/build_shimmer_custom_drawer.dart'; // Import the shimmer widget

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool? canAdd; // Store the result of canAddEstate()

  @override
  void initState() {
    super.initState();
    checkEstateStatus();
  }

  Future<void> checkEstateStatus() async {
    bool result = await canAddEstate();
    setState(() {
      canAdd = result;
    });
  }

  Future<void> _launchTermsUrl() async {
    const url = 'https://www.diamondstel.com/Home/privacypolicy';
    try {
      bool launched = await launch(url, forceWebView: false);
      print('Launch successful: $launched');
    } catch (e) {
      print('Error launching maps: $e');
    }
  }

  Future<bool> canAddEstate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    String userId = user.uid;
    print("My user ID is: $userId");

    List<String> estateCategories = ["Coffee", "Hottel", "Restaurant"];

    try {
      final DatabaseReference estateRef =
          FirebaseDatabase.instance.ref("App/Estate");

      for (String category in estateCategories) {
        final DatabaseReference categoryRef = estateRef.child(category);

        final DatabaseEvent event = await categoryRef.once();
        final DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
          final estates = snapshot.value as Map<dynamic, dynamic>;

          for (var estate in estates.entries) {
            final estateData = estate.value as Map<dynamic, dynamic>;

            if (estateData['IDUser'] == userId) {
              print("User ID matches an estate in category: $category");

              if (estateData['IsAccepted'] == '1' ||
                  estateData['IsAccepted'] == '2') {
                print(
                    "Estate is accepted or under process. Cannot add another estate.");
                return false;
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching estate data: $e");
    }

    return true;
  }

  Widget _buildShimmerOrItem({
    required bool isLoading,
    required IconData icon,
    required String text,
    required String hint,
    required VoidCallback onTap,
  }) {
    if (isLoading) {
      return CustomDrawerShimmerLoading(
        icon: Icons.settings,
      );
    }
    return DrawerItem(
      icon: Icon(icon, color: kDeepPurpleColor),
      text: text,
      hint: hint,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? kDarkModeColor
          : Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.transparent,
                    ),
                    ClipOval(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Shimmer Loading for all drawer items
            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.person,
              text: getTranslated(context, "User's Profile"),
              hint: getTranslated(context, "You can view your data here"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreenUser()));
              },
            ),

            // ✅ Condition applies only to "Add an Estate"
            if (canAdd == null)
              const CustomDrawerShimmerLoading(
                icon: Icons.add,
              )
            else if (canAdd == true)
              DrawerItem(
                icon: Icon(Icons.add, color: kDeepPurpleColor),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          TypeEstate(Check: "Add an Estate")));
                },
                hint:
                    getTranslated(context, "From here you can add an estate."),
                text: getTranslated(context, "Add an Estate"),
              ),

            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Bootstrap.file_text,
              text: getTranslated(context, "Posts"),
              hint: getTranslated(context, "Show the Post"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AllPostsScreen()));
              },
            ),

            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.notification_add,
              text: getTranslated(context, "Notification"),
              hint: getTranslated(context,
                  "You can see the notifications that come to you, such as booking confirmation"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProviderNotificationScreen()));
              },
            ),
            Consumer<GeneralProvider>(
              builder: (context, provider, child) {
                return _buildShimmerOrItem(
                  isLoading: canAdd == null,
                  icon: Bootstrap.book,
                  text: getTranslated(context, "Request"),
                  hint: getTranslated(
                      context, "Receive booking requests from here"),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RequestScreen()));
                  },
                );
              },
            ),

            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.update,
              text: getTranslated(context, "Upgrade account"),
              hint: getTranslated(
                  context, "From here you can upgrade account to Vip"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UpgradeAccountScreen()));
              },
            ),

            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.settings,
              text: getTranslated(context, "Theme Settings"),
              hint: '',
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.privacy_tip,
              text: getTranslated(context, "Privacy & Policy"),
              hint: '',
              onTap: () {
                _launchTermsUrl();
              },
            ),
            _buildShimmerOrItem(
              isLoading: canAdd == null,
              icon: Icons.logout,
              text: getTranslated(context, "Logout"),
              hint: '',
              onTap: () {
                showLogoutConfirmationDialog(context, () async {
                  await LogOutMethod().logOut(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
