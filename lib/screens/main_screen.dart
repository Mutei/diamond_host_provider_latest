// main_screen.dart
import 'dart:async';

import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import 'package:daimond_host_provider/screens/request_screen.dart';
import 'package:daimond_host_provider/screens/edit_estate_screen.dart';
import 'package:daimond_host_provider/screens/edit_estate_hotel_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/firebase_services.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'all_posts_screen.dart';
import 'main_screen_content.dart';
import 'login_screen.dart';

enum _DeviceScopeType { none, all, estate }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool isPersonalInfoMissing = false;
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> dataUser = {};

  // Per-device notifications
  String? _currentFcmToken;
  StreamSubscription<String>? _tokenRefreshSub;

  // Listener for disabled accounts
  StreamSubscription<User?>? _disabledListener;

  // prevent multiple popups within the same foreground session
  bool _dialogShownThisResume = false;

  final List<Widget> _screens = [
    const MainScreenContent(),
    BookingScreen(),
    const AllPostsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    checkPersonalInfo();
    checkEstateBranchInfo();
    FirebaseServices().initMessage();
    _registerDeviceToken();
    _initializeDisabledListener();

    // First-frame check (app just opened)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNewRequestsDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenRefreshSub?.cancel();
    _disabledListener?.cancel();
    super.dispose();
  }

  // Foreground/background tracking
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dialogShownThisResume = false; // reset for this resume
      _maybeShowNewRequestsDialog();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // next time we resume, we allow dialog again
      _dialogShownThisResume = false;
    }
  }

  /// -------- Per-device token registration (multi-device support) --------
  Future<void> _registerDeviceToken() async {
    try {
      _currentFcmToken = await FirebaseMessaging.instance.getToken();
      if (_currentFcmToken == null) return;
      await _saveToken(_currentFcmToken!);

      // Keep token fresh
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        _currentFcmToken = newToken;
        await _saveToken(newToken);
      });
    } catch (e) {
      debugPrint('[_registerDeviceToken] $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final tokensRef =
          FirebaseDatabase.instance.ref('App/User/$uid/Tokens/$token');

      await tokensRef.set({
        'createdAt': ServerValue.timestamp,
        'active': true,
      });
    } catch (e) {
      debugPrint('[saveToken] $e');
    }
  }

  // --------- Scoped dialog helpers ---------

  Future<({_DeviceScopeType type, String? estateId})> _getDeviceScope() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseMessaging.instance.getToken();
      if (uid == null) {
        return (type: _DeviceScopeType.none, estateId: null);
      }

      // 1) Token scope
      if (token != null) {
        final tokenScopeSnap = await FirebaseDatabase.instance
            .ref('App/User/$uid/Tokens/$token/scope')
            .get();

        final t = tokenScopeSnap.child('type').value?.toString();
        if (t == 'all') {
          return (type: _DeviceScopeType.all, estateId: null);
        }
        if (t == 'estate') {
          final e = tokenScopeSnap.child('estateId').value?.toString();
          if (e != null && e.isNotEmpty) {
            return (type: _DeviceScopeType.estate, estateId: e);
          }
        }
      }

      // 2) User-wide scope
      final userScopeSnap = await FirebaseDatabase.instance
          .ref('App/User/$uid/CurrentScope')
          .get();
      final userType = userScopeSnap.child('type').value?.toString();
      if (userType == 'all') {
        return (type: _DeviceScopeType.all, estateId: null);
      }
      if (userType == 'estate') {
        final e = userScopeSnap.child('estateId').value?.toString();
        if (e != null && e.isNotEmpty) {
          return (type: _DeviceScopeType.estate, estateId: e);
        }
      }

      // 3) SharedPreferences fallback (your scope picker keys)
      final sp = await SharedPreferences.getInstance();
      final isAll = sp.getBool('scope.isAll') ?? false;
      if (isAll) {
        return (type: _DeviceScopeType.all, estateId: null);
      } else {
        final savedId = sp.getString('scope.estateId');
        if (savedId != null && savedId.isNotEmpty) {
          return (type: _DeviceScopeType.estate, estateId: savedId);
        }
      }

      return (type: _DeviceScopeType.none, estateId: null);
    } catch (_) {
      return (type: _DeviceScopeType.none, estateId: null);
    }
  }

  Future<int> _countPendingRequests({
    required _DeviceScopeType scopeType,
    String? estateId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    // Query bookings for this provider, then filter on estate if needed
    final ref = FirebaseDatabase.instance
        .ref('App/Booking/Book')
        .orderByChild('IDOwner')
        .equalTo(uid);
    final snap = await ref.get();
    if (!snap.exists) return 0;

    int cnt = 0;
    for (final c in snap.children) {
      final v = c.value;
      if (v is Map) {
        final statusRaw = v['Status'];
        final isPending = statusRaw == '1' || statusRaw == 1;
        if (!isPending) continue;

        if (scopeType == _DeviceScopeType.estate) {
          final eId = v['IDEstate']?.toString();
          if (eId != estateId) continue;
        }
        // scopeType == all → no estate filter
        cnt++;
      }
    }
    return cnt;
  }

  Future<void> _maybeShowNewRequestsDialog() async {
    if (!mounted || _dialogShownThisResume) return;

    final scope = await _getDeviceScope();

    // No scope → do not show any dialog
    if (scope.type == _DeviceScopeType.none) return;

    final pendingCount = await _countPendingRequests(
      scopeType: scope.type,
      estateId: scope.estateId,
    );

    if (pendingCount > 0 && mounted) {
      _dialogShownThisResume = true; // show once per foreground session
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(getTranslated(context, "New Booking Request")),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getTranslated(context, "You have")),
              Text(
                " $pendingCount ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(getTranslated(context, "new booking request(s).")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(getTranslated(context, "OK")),
            ),
          ],
        ),
      );
    }
  }

  /// Initialize listener to detect if the user's Firebase Auth account is disabled
  Future<void> _initializeDisabledListener() async {
    _disabledListener = FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user != null) {
        user.getIdToken(true).catchError((err) {
          if (err is FirebaseAuthException && err.code == 'user-disabled') {
            _signOut();
          }
        });
      }
    });
  }

  /// Sign the user out and navigate back to the login screen
  Future<void> _signOut() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && _currentFcmToken != null) {
        final tokensRef = FirebaseDatabase.instance
            .ref('App/User/$uid/Tokens/${_currentFcmToken!}');
        await tokensRef.remove();
      }
    } catch (e) {
      debugPrint('[signOut] token cleanup failed: $e');
    }

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  /// New: Check if any of user's estates have missing branches
  Future<void> checkEstateBranchInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final estateTypes = ['Hottel', 'Restaurant', 'Coffee'];

      for (String type in estateTypes) {
        final estateRef = FirebaseDatabase.instance.ref("App/Estate/$type");
        final snapshot = await estateRef.get();

        if (snapshot.exists && snapshot.value != null) {
          final estates = Map<String, dynamic>.from(snapshot.value as Map);
          for (var entry in estates.entries) {
            final estateId = entry.key;
            final estateData = Map<String, dynamic>.from(entry.value as Map);
            if (estateData['IDUser'] == uid) {
              final branchEn = estateData['BranchEn'] ?? '';
              final branchAr = estateData['BranchAr'] ?? '';
              final nameEn = estateData['NameEn'] ?? 'this estate';
              final nameAr = estateData['NameAr'] ?? 'this estate';
              final String languageCode =
                  Localizations.localeOf(context).languageCode;
              final String displayName = languageCode == 'ar' ? nameAr : nameEn;

              if (branchEn.toString().isEmpty || branchAr.toString().isEmpty) {
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title:
                        Text(getTranslated(context, "Incomplete Branch Info")),
                    content: Text(
                      "${getTranslated(context, "Please fill out the branches in English and Arabic for")} ($displayName)",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(getTranslated(context, "Cancel")),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => type == 'Hottel'
                                  ? EditEstateHotel(
                                      objEstate: estateData,
                                      LstRooms: [],
                                      estateType: '1',
                                      estateId: estateId,
                                    )
                                  : EditEstate(
                                      objEstate: estateData,
                                      LstRooms: [],
                                      estateType:
                                          type == 'Restaurant' ? '3' : '2',
                                      estateId: estateId,
                                    ),
                            ),
                          );
                        },
                        child: Text(getTranslated(context, "Update Info")),
                      ),
                    ],
                  ),
                );
                return; // Only show once
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking estate branch info: $e");
    }
  }

  /// Check if personal info is missing and prompt update
  Future<void> checkPersonalInfo() async {
    try {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('App').child('User').child(userId);
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        dataUser = Map<String, dynamic>.from(snapshot.value as Map);

        bool isFirstNameMissing = dataUser['FirstName'] == null ||
            dataUser['FirstName'].toString().isEmpty;
        // bool isSecondNameMissing = dataUser['SecondName'] == null ||
        //     dataUser['SecondName'].toString().isEmpty;
        bool isLastNameMissing = dataUser['LastName'] == null ||
            dataUser['LastName'].toString().isEmpty;
        // bool isCityMissing =
        //     dataUser['City'] == null || dataUser['City'].toString().isEmpty;
        // bool isCountryMissing = dataUser['Country'] == null ||
        //     dataUser['Country'].toString().isEmpty;
        // bool isStateMissing =
        //     dataUser['State'] == null || dataUser['State'].toString().isEmpty;

        if (isFirstNameMissing ||
                // isSecondNameMissing ||
                isLastNameMissing
            // ||
            // isCityMissing ||
            // isStateMissing ||
            // isCountryMissing
            ) {
          setState(() => isPersonalInfoMissing = true);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getTranslated(context,
                    "Your personal information is incomplete. Please fill out the required fields."),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          showAlertDialog();
        }
      }
    } catch (error) {
      debugPrint("Error fetching user data: $error");
    }
  }

  void showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Incomplete Profile")),
          content: Text(getTranslated(context,
              "Your personal information is incomplete. Please fill out the required fields.")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(getTranslated(context, "Cancel")),
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
                      state: dataUser['State'] ?? '',
                    ),
                  ),
                );
              },
              child: Text(getTranslated(context, "Update Info")),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
