// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../screens/login_screen.dart';
//
// class LogOutMethod {
//   final _database = FirebaseDatabase.instance.ref();
//
//   Future<void> logOut(BuildContext context) async {
//     try {
//       // Show a loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return const Center(child: CircularProgressIndicator());
//         },
//       );
//
//       // Get current user ID before logging out
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//
//       if (userId != null) {
//         await _database.child('App/User/$userId/Token').remove();
//       }
//
//       // Clear SharedPreferences and force a new instance
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.remove(
//           "userId"); // Clears all stored data including userId// Clear all stored data
//       await prefs.reload(); // Ensure SharedPreferences is refreshed
//
//       // Sign out the user
//       await FirebaseAuth.instance.signOut();
//       print("User logged out: $userId");
//
//       // Close the loading indicator
//       Navigator.of(context).pop();
//
//       // Navigate to the Login Screen
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (context) => LoginScreen(),
//         ),
//       );
//     } catch (e) {
//       // Handle logout error
//       Navigator.of(context).pop(); // Close the loading indicator
//       print('Error logging out: $e');
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class LogOutMethod {
  final _db = FirebaseDatabase.instance.ref();

  Future<void> logOut(BuildContext context) async {
    try {
      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      // Remove THIS device's token only
      if (uid != null) {
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await _db.child('App/User/$uid/Tokens/$token').remove();
          }
        } catch (e) {
          debugPrint('[LogOut] token removal failed: $e');
        }
      }

      // Clear local session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.reload();

      // Sign out
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pop(); // close loader
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // close loader
      debugPrint('Error logging out: $e');
    }
  }
}
