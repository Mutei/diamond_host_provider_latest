// lib/state_management/general_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../localization/language_constants.dart';

enum ThemeModeType { system, light, dark }

// Class to represent post status change events
class PostStatusChangeEvent {
  final String postId;
  final String status; // '1' for approved, '2' for rejected

  PostStatusChangeEvent({required this.postId, required this.status});
}

class GeneralProvider with ChangeNotifier, DiagnosticableTreeMixin {
  Color color = Color(0xFFE8C75B);
  bool CheckLangValue = true;
  bool CheckLoginValue = false;
  Map UserMap = {};
  int _newRequestCount = 0;
  int _chatRequestCount = 0;
  Map<String, bool> _chatAccessPerEstate = {};
  int _approvalCount = 0;
  int _lastSeenApprovalCount = 0;
  ThemeModeType _themeMode = ThemeModeType.system;
  int get newRequestCount => _newRequestCount;
  int get chatRequestCount => _chatRequestCount;
  int get approvalCount => _approvalCount;
  String _subscriptionType = '1'; // Default to Star
  DateTime? _subscriptionExpiryTime;
  Timer? _subscriptionTimer;
  final StreamController<void> _subscriptionExpiredController =
      StreamController<void>.broadcast();
  String get subscriptionType => _subscriptionType;

  // Stream for subscription expiration
  Stream<void> get subscriptionExpiredStream =>
      _subscriptionExpiredController.stream;

  ThemeModeType get themeMode => _themeMode;

  // StreamController for post status changes
  final StreamController<PostStatusChangeEvent> _postStatusChangeController =
      StreamController<PostStatusChangeEvent>.broadcast();

  // Getter for the post status change stream
  Stream<PostStatusChangeEvent> get postStatusChangeStream =>
      _postStatusChangeController.stream;

  // Map to track the current status of user's posts
  Map<String, String> _userPostStatuses = {};

  GeneralProvider() {
    loadThemePreference();
    loadLastSeenApprovalCount();
    fetchApprovalCount();
    fetchNewRequestCount();
    CheckLogin();
    fetchAndSetUserInfo(); // Fetch user info and start listening to post status changes
  }

  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
  }

  void toggleTheme(ThemeModeType themeModeType) async {
    _themeMode = themeModeType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeModeType.index);
  }

  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // If no theme is saved, default to light
    _themeMode = ThemeModeType
        .values[prefs.getInt('themeMode') ?? ThemeModeType.light.index];
    notifyListeners();
  }

  Future<void> fetchSubscriptionStatus() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      DatabaseEvent event = await ref.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _subscriptionType = data['TypeAccount'] ?? '1';
        String? expiryTimeString = data['SubscriptionExpiryTime'];
        if (expiryTimeString != null) {
          _subscriptionExpiryTime = DateTime.parse(expiryTimeString);
          if (_subscriptionType != '1' &&
              _subscriptionExpiryTime!.isAfter(DateTime.now())) {
            Duration remaining =
                _subscriptionExpiryTime!.difference(DateTime.now());
            startSubscriptionTimer(remaining);
          } else if (_subscriptionType != '1' &&
              _subscriptionExpiryTime!.isBefore(DateTime.now())) {
            // Subscription expired, revert to '1'
            await ref
                .update({'TypeAccount': '1', 'SubscriptionExpiryTime': null});
            _subscriptionType = '1';
            notifyListeners();
            // Notify subscription expired
            _subscriptionExpiredController.add(null);
          }
        }
      }
    }
  }

  Future<void> startSubscription(String newType, Duration duration) async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DateTime expiryTime = DateTime.now().add(duration);
      String formattedExpiryDate =
          DateFormat('yyyy-MM-dd').format(expiryTime); // Format the date
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      try {
        await ref.update({
          'TypeAccount': newType,
          'SubscriptionExpiryTime': formattedExpiryDate // Save as a normal date
        });
        _subscriptionType = newType;
        _subscriptionExpiryTime = expiryTime;
        startSubscriptionTimer(duration);
        notifyListeners();
      } catch (e) {
        // Handle error
        print('Error starting subscription: $e');
      }
    }
  }

  void startSubscriptionTimer(Duration duration) {
    _subscriptionTimer?.cancel();
    _subscriptionTimer = Timer(duration, onSubscriptionExpired);
  }

  Future<void> onSubscriptionExpired() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      try {
        await ref.update({'TypeAccount': '1', 'SubscriptionExpiryTime': null});
        _subscriptionType = '1';
        notifyListeners();
        // Notify subscribers
        _subscriptionExpiredController.add(null);
      } catch (e) {
        print('Error reverting subscription: $e');
      }
    }
  }

  ThemeData getTheme(BuildContext context) {
    switch (_themeMode) {
      case ThemeModeType.dark:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kDarkModeColor,
          primaryColor: kDarkModeColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kDarkModeColor,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                kPurpleColor, // Using the custom purple color as the seed
            brightness: Brightness.dark,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        );
      case ThemeModeType.light:
        return ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                kPurpleColor, // Using the custom purple color as the seed
            brightness: Brightness.light,
          ),
        );
      case ThemeModeType.system:
      default:
        var brightness = MediaQuery.of(context).platformBrightness;
        if (brightness == Brightness.dark) {
          return ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kDarkModeColor,
            primaryColor: kDarkModeColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: kDarkModeColor,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor:
                  kPurpleColor, // Using the custom purple color as the seed
              brightness: Brightness.dark,
            ),
            textTheme: ThemeData.dark().textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
          );
        } else {
          return ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor:
                  kPurpleColor, // Using the custom purple color as the seed
              brightness: Brightness.light,
            ),
          );
        }
    }
  }
  // ThemeData getTheme(BuildContext context) {
  //   switch (_themeMode) {
  //     case ThemeModeType.dark:
  //       return ThemeData(
  //         brightness: Brightness.dark,
  //         scaffoldBackgroundColor: kDarkModeColor, // Custom background color
  //         primaryColor: kDarkModeColor,
  //         appBarTheme: const AppBarTheme(
  //           backgroundColor: kDarkModeColor,
  //         ),
  //         // You can customize other properties as needed
  //         // For example, text themes, button themes, etc.
  //         // Example:
  //         textTheme: ThemeData.dark().textTheme.apply(
  //               bodyColor: Colors.white,
  //               displayColor: Colors.white,
  //             ),
  //         // Add more customizations here
  //       );
  //     case ThemeModeType.light:
  //       return ThemeData.light();
  //     case ThemeModeType.system:
  //     default:
  //       var brightness = MediaQuery.of(context).platformBrightness;
  //       if (brightness == Brightness.dark) {
  //         return ThemeData(
  //           brightness: Brightness.dark,
  //           scaffoldBackgroundColor: kDarkModeColor, // Custom background color
  //           primaryColor: kDarkModeColor,
  //           appBarTheme: const AppBarTheme(
  //             backgroundColor: kDarkModeColor,
  //           ),
  //           // Additional customizations if needed
  //           textTheme: ThemeData.dark().textTheme.apply(
  //                 bodyColor: Colors.white,
  //                 displayColor: Colors.white,
  //               ),
  //           // Add more customizations here
  //         );
  //       } else {
  //         return ThemeData.light();
  //       }
  //   }
  // }

  void fetchApprovalCount() {
    FirebaseDatabase.instance
        .ref("App/Booking/Book")
        .onValue
        .listen((DatabaseEvent event) async {
      int totalApprovals = 0;
      if (event.snapshot.value != null) {
        Map bookings = event.snapshot.value as Map;
        bookings.forEach((key, value) {
          if (value["Status"] == "2" || value["Status"] == "3") {
            totalApprovals++;
          }
        });
      }
      _approvalCount = totalApprovals - _lastSeenApprovalCount;
      if (_approvalCount < 0) _approvalCount = 0;
      notifyListeners();
    });
  }

  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount;
    _approvalCount = 0;
    saveLastSeenApprovalCount(_lastSeenApprovalCount);
    notifyListeners();
  }

  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
  }

  void fetchNewRequestCount() {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      FirebaseDatabase.instance
          .ref("App/Booking/Book")
          .orderByChild("IDOwner")
          .equalTo(id)
          .onValue // Use onValue for real-time updates
          .listen((DatabaseEvent event) {
        int count = 0;
        if (event.snapshot.value != null) {
          Map requests = event.snapshot.value as Map;
          requests.forEach((key, value) {
            if (value["Status"] == "1") {
              count++;
            }
          });
        }
        _newRequestCount = count;
        notifyListeners(); // Update listeners directly when there's a new request
      });
    }
  }

  bool hasChatAccessForEstate(String estateId) {
    return _chatAccessPerEstate[estateId] ?? false;
  }

  void updateChatAccessForEstate(String estateId, bool access) {
    _chatAccessPerEstate[estateId] = access;
    notifyListeners();
  }

  Future getUer() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    DatabaseReference starCountRef = FirebaseDatabase.instance
        .ref("App")
        .child("User")
        .child(sharedPreferences.getString("ID")!);
    starCountRef.onValue.listen((DatabaseEvent event) {
      UserMap = event.snapshot.value as Map;
    });
    notifyListeners();
  }

  List<CustomerType> TypeService(BuildContext context) {
    List<CustomerType> LstCustomerType = [];

    LstCustomerType.add(CustomerType(
      icon: Icons.restaurant,
      name: getTranslated(context, "Restaurant"), // Key for translation
      type: "3",
      subtext: getTranslated(
          context, "Add your restaurant from here"), // Key for translation
    ));

    LstCustomerType.add(CustomerType(
      icon: Icons.local_cafe,
      name: getTranslated(context, "Coffee"), // Key for translation
      type: "2",
      subtext: getTranslated(
          context, "Add your Coffee from here"), // Key for translation
    ));

    LstCustomerType.add(CustomerType(
      icon: Icons.hotel,
      name: getTranslated(context, "Hotel"), // Key for translation
      type: "1",
      subtext: getTranslated(
          context, "Add your Hotel from here"), // Key for translation
    ));

    return LstCustomerType;
  }

  Future<bool> CheckLang() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? lang = sharedPreferences.getString("Language");
    if (lang == null || lang.isEmpty) {
      CheckLangValue = true;
      return true;
    } else if (lang == "en") {
      CheckLangValue = true;
      return true;
    } else if (lang == "ar") {
      CheckLangValue = false;
      return false;
    }
    return true;
  }

  void updateLanguage(bool isEnglish) {
    CheckLangValue = isEnglish;
    notifyListeners();
  }

  void CheckLogin() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("TypeUser") == "1") {
      CheckLoginValue = false;
    } else {
      CheckLoginValue = true;
    }
  }

  void resetNewRequestCount() {
    _newRequestCount = 0;
    notifyListeners();
  }

  // -------------------- Post Status Change Handling --------------------

  // Fetch and set user information, then start listening to post status changes
  Future<void> fetchAndSetUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is currently logged in.');
      return; // No user is logged in
    }

    try {
      final userRef = FirebaseDatabase.instance.ref('App/User/${user.uid}');
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final userId = data['userId'] ?? '';
        final firstName = data['FirstName'] ?? 'Anonymous';
        final lastName = data['LastName'] ?? '';

        // Update userName
        final userName = '$firstName $lastName';

        // Save in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);

        // Update provider state
        // You can add _userId and _userName if needed
        print('User info fetched and set: $userId, $userName');
        notifyListeners();

        // Start listening to post status changes after fetching user info
        listenToUserPostStatusChanges();
      } else {
        print('User data does not exist in Firebase for UID: ${user.uid}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  // Method to listen to post status changes for the current user
  void listenToUserPostStatusChanges() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user available to listen for post status changes.');
      return;
    }
    String userId = user.uid;

    FirebaseDatabase.instance
        .ref("App/AllPosts")
        .orderByChild("userId")
        .equalTo(userId)
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> postsData =
            event.snapshot.value as Map<dynamic, dynamic>;
        postsData.forEach((key, value) {
          String postId = key;
          String status = value['Status'] ?? '0';
          if (_userPostStatuses.containsKey(postId)) {
            String oldStatus = _userPostStatuses[postId]!;
            if (oldStatus != status && (status == '1' || status == '2')) {
              // Status changed to '1' or '2'
              _postStatusChangeController
                  .add(PostStatusChangeEvent(postId: postId, status: status));
              print('Post $postId status changed to $status. Event emitted.');
            }
          }
          _userPostStatuses[postId] = status;
        });
      }
    }, onError: (error) {
      print('Error listening to post status changes: $error');
    });
  }

  @override
  void dispose() {
    _postStatusChangeController.close(); // Close the post status controller
    super.dispose();
  }
}

class CustomerType {
  late String name, type, subtext;
  late IconData icon; // Changed from image to IconData

  CustomerType({
    required this.icon, // Use icon instead of image
    required this.name,
    required this.type,
    required this.subtext,
  });
}
