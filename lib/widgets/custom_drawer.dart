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
import '../screens/main_screen.dart';
import '../screens/provider_notification_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/type_estate_screen.dart';
import '../state_management/general_provider.dart';
import '../utils/global_methods.dart';
import 'item_drawer.dart';
import 'package:firebase_database/firebase_database.dart';

// NEW:
import '../backend/access_scope.dart';

// NEW imports for scope resolution
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool? canAdd;
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _resolveOwnerFlag();
  }

  Future<void> _resolveOwnerFlag() async {
    bool isOwner = true;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseMessaging.instance.getToken();

      if (uid != null && token != null) {
        final tokenScopeSnap = await FirebaseDatabase.instance
            .ref('App/User/$uid/Tokens/$token/scope')
            .get();
        if (tokenScopeSnap.exists) {
          final type = tokenScopeSnap.child('type').value?.toString();
          if (type == 'estate') isOwner = false;
          if (type == 'all') isOwner = true;
        } else {
          final userScopeSnap = await FirebaseDatabase.instance
              .ref('App/User/$uid/CurrentScope')
              .get();
          if (userScopeSnap.exists) {
            final type = userScopeSnap.child('type').value?.toString();
            if (type == 'estate') isOwner = false;
            if (type == 'all') isOwner = true;
          } else {
            final sp = await SharedPreferences.getInstance();
            final isAll = sp.getBool('scope.isAll') ?? false;
            final estateId = sp.getString('scope.estateId');
            if (isAll) {
              isOwner = true;
            } else if (estateId != null && estateId.isNotEmpty) {
              isOwner = false;
            } else {
              isOwner = true;
            }
          }
        }
      }
    } catch (_) {}

    setState(() {
      _isOwner = isOwner;
    });

    if (isOwner) {
      await checkEstateStatus();
    }
  }

  Future<void> checkEstateStatus() async {
    bool result = await canAddEstate();
    if (mounted) {
      setState(() {
        canAdd = result;
      });
    }
  }

  Future<bool> canAddEstate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    String userId = user.uid;
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
              final isAccepted = (estateData['IsAccepted'] ?? '').toString();
              final isCompleted = (estateData['IsCompleted'] ?? '').toString();
              if (isAccepted == '1') return false;
              if (isCompleted == '0') return false;
            }
          }
        }
      }
    } catch (_) {}
    return true;
  }

  Future<void> _launchTermsUrl() async {
    const url = 'https://redakapp.com/privacy-policy';
    try {
      await launch(url, forceWebView: false);
    } catch (_) {}
  }

  // Simplified (no shimmer)
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required String hint,
    required VoidCallback onTap,
  }) {
    return DrawerItem(
      icon: Icon(icon, color: kDeepPurpleColor),
      text: text,
      hint: hint,
      onTap: onTap,
    );
  }

  Future<void> _changeScope() async {
    await AccessScopeStore.clear();
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
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
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              text: getTranslated(context, "User's Profile"),
              hint: getTranslated(context, "You can view your data here"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreenUser()));
              },
            ),
            if (_isOwner)
              _buildDrawerItem(
                icon: Icons.add,
                text: getTranslated(context, "Add an Estate"),
                hint:
                    getTranslated(context, "From here you can add an estate."),
                onTap: () {
                  if (canAdd == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          getTranslated(context,
                              "You cannot add a new estate at the moment."),
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          TypeEstate(Check: "Add an Estate")));
                },
              ),
            _buildDrawerItem(
              icon: Bootstrap.file_text,
              text: getTranslated(context, "Posts"),
              hint: getTranslated(context, "Show the Post"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AllPostsScreen()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.notification_add,
              text: getTranslated(context, "Provider Notifications"),
              hint: getTranslated(context,
                  "You can see the notifications that come to you, such as booking confirmation"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProviderNotificationScreen()));
              },
            ),
            Consumer<GeneralProvider>(
              builder: (context, provider, child) {
                return _buildDrawerItem(
                  icon: Bootstrap.book,
                  text: getTranslated(context, "Request"),
                  hint: getTranslated(
                      context, "Receive booking requests from here"),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => BookingScreen()));
                  },
                );
              },
            ),
            // _buildDrawerItem(
            //   icon: Icons.update,
            //   text: getTranslated(context, "Upgrade account"),
            //   hint: getTranslated(
            //       context, "From here you can upgrade account to Vip"),
            //   onTap: () {
            //     Navigator.of(context).push(MaterialPageRoute(
            //         builder: (context) => UpgradeAccountScreen()));
            //   },
            // ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: getTranslated(context, "Theme Settings"),
              hint: '',
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            // DrawerItem(
            //   icon: const Icon(Icons.key, color: kDeepPurpleColor),
            //   text: getTranslated(context, "Change scope"),
            //   hint: getTranslated(context, "Switch the estate you manage"),
            //   onTap: _changeScope,
            // ),
            _buildDrawerItem(
              icon: Icons.privacy_tip,
              text: getTranslated(context, "Privacy & Policy"),
              hint: '',
              onTap: _launchTermsUrl,
            ),
            _buildDrawerItem(
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
