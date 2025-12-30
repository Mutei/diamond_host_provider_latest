// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// import '../constants/colors.dart';
// import '../state_management/general_provider.dart';
// import '../localization/language_constants.dart';
// import '../main.dart';
// import '../utils/failure_dialogue.dart';
// import '../widgets/reused_appbar.dart';
//
// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});
//
//   // -------------------- Helpers --------------------
//
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final uri = Uri(scheme: 'tel', path: phoneNumber);
//     await launchUrl(uri);
//   }
//
//   Future<void> _showDeletionProgress(
//     BuildContext parentContext,
//     String password,
//   ) async {
//     bool isExecuting = false;
//     await showDialog(
//       context: parentContext,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         double progress = 0.0;
//         return StatefulBuilder(
//           builder: (context, setState) {
//             if (!isExecuting) {
//               isExecuting = true;
//               _deleteAccountWithProgress(
//                 parentContext,
//                 password,
//                 dialogContext,
//                 (p) => setState(() => progress = p.clamp(0.0, 1.0)),
//               );
//             }
//             return AlertDialog(
//               title: Text(getTranslated(parentContext, 'Deleting Account')),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   LinearProgressIndicator(
//                       value: progress > 0 && progress < 1 ? progress : null),
//                   const SizedBox(height: 16),
//                   Text('${(progress * 100).round()}%'),
//                   const SizedBox(height: 8),
//                   Text(
//                     getTranslated(
//                       parentContext,
//                       "Please don't close the application until your account is deleted successfully",
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _deleteAccountWithProgress(
//     BuildContext parentContext,
//     String password,
//     BuildContext dialogContext,
//     void Function(double) updateProgress,
//   ) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         Navigator.of(dialogContext).pop();
//         return;
//       }
//
//       // 1) Reauthenticate
//       final email = user.email!;
//       final credential =
//           EmailAuthProvider.credential(email: email, password: password);
//       await user.reauthenticateWithCredential(credential);
//       updateProgress(0.10);
//
//       final userId = user.uid;
//       final dbRef = FirebaseDatabase.instance.ref();
//
//       // 2) Delete user info
//       await dbRef.child('App/User/$userId').remove();
//       updateProgress(0.25);
//
//       // 3) Delete estates + related feedback + estate chats
//       //    App/Estate/<Category>/<EstateId> where Estate.IDUser == userId
//       //    App/CustomerFeedback where EstateID == estateId
//       //    App/EstateChats/<EstateId>
//       final estateSnap = await dbRef.child('App/Estate').once();
//       if (estateSnap.snapshot.value != null) {
//         final estatesRoot = estateSnap.snapshot.value;
//         if (estatesRoot is Map) {
//           // Pre-load feedback map once to avoid multiple reads
//           Map feedbacks = {};
//           final feedbackSnap = await dbRef.child('App/CustomerFeedback').once();
//           if (feedbackSnap.snapshot.value != null &&
//               feedbackSnap.snapshot.value is Map) {
//             feedbacks = feedbackSnap.snapshot.value as Map;
//           }
//
//           double itemsProcessed = 0;
//           final categories = estatesRoot.entries.toList();
//           final totalCategories = categories.isEmpty ? 1 : categories.length;
//
//           for (final categoryEntry in categories) {
//             final categoryKey = categoryEntry.key;
//             final categoryVal = categoryEntry.value;
//
//             if (categoryVal is Map) {
//               for (final estateEntry in categoryVal.entries) {
//                 final estateId = estateEntry.key;
//                 final estateData = estateEntry.value;
//
//                 final estateOwnerId =
//                     (estateData is Map && estateData['IDUser'] != null)
//                         ? estateData['IDUser'].toString()
//                         : null;
//
//                 if (estateOwnerId == userId) {
//                   // Delete feedback for this estate
//                   if (feedbacks.isNotEmpty) {
//                     for (final fbEntry in feedbacks.entries) {
//                       final fbId = fbEntry.key;
//                       final fbData = fbEntry.value;
//                       if (fbData is Map && fbData['EstateID'] == estateId) {
//                         await dbRef
//                             .child('App/CustomerFeedback/$fbId')
//                             .remove();
//                       }
//                     }
//                   }
//
//                   // Delete estate chat
//                   await dbRef.child('App/EstateChats/$estateId').remove();
//
//                   // Delete estate
//                   await dbRef
//                       .child('App/Estate/$categoryKey/$estateId')
//                       .remove();
//                 }
//               }
//             }
//
//             // Bump progress within 0.25 -> 0.55 range based on categories processed
//             itemsProcessed += 1;
//             final catProgress =
//                 0.25 + (itemsProcessed / totalCategories) * 0.30;
//             updateProgress(catProgress);
//           }
//         }
//       } else {
//         updateProgress(0.55);
//       }
//
//       // 4) Delete posts (App/AllPosts where userId == current)
//       final postsSnap = await dbRef.child('App/AllPosts').once();
//       if (postsSnap.snapshot.value != null && postsSnap.snapshot.value is Map) {
//         final posts = postsSnap.snapshot.value as Map;
//         for (final postEntry in posts.entries) {
//           final postId = postEntry.key;
//           final postData = postEntry.value;
//           if (postData is Map && postData['userId'] == userId) {
//             await dbRef.child('App/AllPosts/$postId').remove();
//           }
//         }
//       }
//       updateProgress(0.70);
//
//       // 5) Delete booking requests (App/Booking/Book where IDOwner == current)
//       final bookSnap = await dbRef.child('App/Booking/Book').once();
//       if (bookSnap.snapshot.value != null && bookSnap.snapshot.value is Map) {
//         final bookings = bookSnap.snapshot.value as Map;
//         for (final bookEntry in bookings.entries) {
//           final bookId = bookEntry.key;
//           final bookData = bookEntry.value;
//           if (bookData is Map && bookData['IDOwner'] == userId) {
//             await dbRef.child('App/Booking/Book/$bookId').remove();
//           }
//         }
//       }
//       updateProgress(0.85);
//
//       // 5.1) Delete AccessPins (App/AccessPins/<userId>)  <-- ADDED
//       await dbRef.child('App/AccessPins/$userId').remove();
//       updateProgress(0.90);
//
//       // 6) Delete auth account + sign out
//       await user.delete();
//       await FirebaseAuth.instance.signOut();
//       updateProgress(1.0);
//
//       // Close progress dialog
//       Navigator.of(dialogContext).pop();
//
//       // Safest: return to first route (e.g., login)
//       if (Navigator.of(parentContext).canPop()) {
//         Navigator.of(parentContext).popUntil((route) => route.isFirst);
//       }
//     } catch (e) {
//       // Close progress dialog if still open
//       if (Navigator.of(dialogContext).canPop()) {
//         Navigator.of(dialogContext).pop();
//       }
//
//       String errorMessage;
//       if (e is FirebaseAuthException && e.code == 'wrong-password') {
//         errorMessage =
//             getTranslated(parentContext, "Your password is incorrect");
//         showDialog(
//           context: parentContext,
//           builder: (context) => const FailureDialog(
//             text: "Incorrect Password!",
//             text1: "Your password is incorrect.",
//           ),
//         );
//       } else if (e is FirebaseAuthException) {
//         errorMessage = e.message ??
//             getTranslated(parentContext, 'An authentication error occurred');
//       } else {
//         errorMessage = e.toString();
//       }
//
//       ScaffoldMessenger.of(parentContext).showSnackBar(
//         SnackBar(content: Text(errorMessage)),
//       );
//     }
//   }
//
//   Future<void> _promptPassword(BuildContext context) async {
//     final parentContext = context;
//     final passwordController = TextEditingController();
//     final confirmPasswordController = TextEditingController();
//
//     await showDialog(
//       context: parentContext,
//       builder: (dialogContext) {
//         bool obscurePassword = true;
//         bool obscureConfirm = true;
//         return StatefulBuilder(
//           builder: (context, setState) => AlertDialog(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             title: Text(getTranslated(parentContext, 'Confirm Password')),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: passwordController,
//                   obscureText: obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: getTranslated(parentContext, 'Password'),
//                     suffixIcon: IconButton(
//                       icon: Icon(obscurePassword
//                           ? Icons.visibility_off
//                           : Icons.visibility),
//                       onPressed: () =>
//                           setState(() => obscurePassword = !obscurePassword),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: confirmPasswordController,
//                   obscureText: obscureConfirm,
//                   decoration: InputDecoration(
//                     labelText: getTranslated(parentContext, 'Confirm Password'),
//                     suffixIcon: IconButton(
//                       icon: Icon(obscureConfirm
//                           ? Icons.visibility_off
//                           : Icons.visibility),
//                       onPressed: () =>
//                           setState(() => obscureConfirm = !obscureConfirm),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(dialogContext).pop(),
//                 child: Text(getTranslated(parentContext, 'Cancel')),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final password = passwordController.text.trim();
//                   final confirmPassword = confirmPasswordController.text.trim();
//
//                   if (password != confirmPassword) {
//                     ScaffoldMessenger.of(parentContext).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           getTranslated(
//                               parentContext, 'Passwords do not match.'),
//                         ),
//                       ),
//                     );
//                     return;
//                   }
//
//                   Navigator.of(dialogContext).pop();
//                   await _showDeletionProgress(parentContext, password);
//                 },
//                 child: Text(
//                   getTranslated(parentContext, 'Confirm Delete'),
//                   style: const TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // -------------------- UI --------------------
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GeneralProvider>(context);
//
//     return Scaffold(
//       appBar: ReusedAppBar(title: getTranslated(context, 'Settings')),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Language Settings
//             Padding(
//               padding:
//                   const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
//               child: Text(
//                 getTranslated(context, 'Language Settings'),
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: kPurpleColor,
//                 ),
//               ),
//             ),
//             ListTile(
//               title: const Text(
//                 'English',
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: kPurpleColor),
//               ),
//               trailing: Radio<bool>(
//                 value: true,
//                 groupValue: provider.CheckLangValue,
//                 onChanged: (value) async {
//                   if (value == null) return;
//                   final sp = await SharedPreferences.getInstance();
//                   await sp.setString('Language', 'en');
//                   MyApp.setLocale(context, const Locale('en', 'SA'));
//                   provider.updateLanguage(value);
//                 },
//                 activeColor: kPurpleColor,
//               ),
//             ),
//             ListTile(
//               title: const Text(
//                 'عربي',
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: kPurpleColor),
//               ),
//               trailing: Radio<bool>(
//                 value: false,
//                 groupValue: provider.CheckLangValue,
//                 onChanged: (value) async {
//                   if (value == null) return;
//                   final sp = await SharedPreferences.getInstance();
//                   await sp.setString('Language', 'ar');
//                   MyApp.setLocale(context, const Locale('ar', 'SA'));
//                   provider.updateLanguage(value);
//                 },
//                 activeColor: kPurpleColor,
//               ),
//             ),
//
//             const Divider(),
//
//             // Call Center
//             Padding(
//               padding:
//                   const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
//               child: Text(
//                 getTranslated(context, 'Call Center'),
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: kPurpleColor,
//                 ),
//               ),
//             ),
//             ListTile(
//               title: const Text(
//                 '920031542',
//                 style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: kPurpleColor),
//               ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.support_agent, color: kPurpleColor),
//                 onPressed: () => _makePhoneCall('920031542'),
//               ),
//             ),
//
//             const Divider(),
//
//             // Delete Account
//             ListTile(
//               title: Text(
//                 getTranslated(context, 'Delete Account'),
//                 style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red),
//               ),
//               subtitle: Text(
//                 getTranslated(
//                     context, 'Permanently delete your account and all data.'),
//                 style: const TextStyle(fontSize: 14, color: Colors.black54),
//               ),
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: const BoxDecoration(
//                     color: Colors.redAccent, shape: BoxShape.circle),
//                 child: const Icon(Icons.delete_forever, color: Colors.white),
//               ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.arrow_forward_ios, color: Colors.red),
//                 onPressed: () => _promptPassword(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// lib/screens/settings_screen.dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../constants/colors.dart';
import '../state_management/general_provider.dart';
import '../localization/language_constants.dart';
import '../main.dart';
import '../utils/failure_dialogue.dart';
import '../widgets/reused_appbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // -------------------- Helpers --------------------

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(uri);
  }

  /// Shows a modal progress dialog and runs the actual deletion steps.
  Future<void> _showDeletionProgress(
    BuildContext parentContext,
  ) async {
    bool isExecuting = false;
    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        double progress = 0.0;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!isExecuting) {
              isExecuting = true;
              _performDeletionWithProgress(
                parentContext,
                dialogContext,
                (p) => setState(() => progress = p.clamp(0.0, 1.0)),
              );
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(getTranslated(parentContext, 'Deleting Account')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress > 0 && progress < 1 ? progress : null,
                  ),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).round()}%'),
                  const SizedBox(height: 8),
                  Text(
                    getTranslated(
                      parentContext,
                      "Please don't close the application until your account is deleted successfully",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Assumes the user is ALREADY reauthenticated. Runs all DB cleanup + delete.
  Future<void> _performDeletionWithProgress(
    BuildContext parentContext,
    BuildContext dialogContext,
    void Function(double) updateProgress,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(dialogContext).pop();
        return;
      }

      final userId = user.uid;
      final dbRef = FirebaseDatabase.instance.ref();

      // 1) Delete user info
      await dbRef.child('App/User/$userId').remove();
      updateProgress(0.15);

      // 2) Delete estates + related feedback + estate chats
      final estateSnap = await dbRef.child('App/Estate').once();
      if (estateSnap.snapshot.value != null) {
        final estatesRoot = estateSnap.snapshot.value;
        if (estatesRoot is Map) {
          // Pre-load feedback map once
          Map feedbacks = {};
          final feedbackSnap = await dbRef.child('App/CustomerFeedback').once();
          if (feedbackSnap.snapshot.value != null &&
              feedbackSnap.snapshot.value is Map) {
            feedbacks = feedbackSnap.snapshot.value as Map;
          }

          double catsProcessed = 0;
          final categories = estatesRoot.entries.toList();
          final totalCategories = categories.isEmpty ? 1 : categories.length;

          for (final categoryEntry in categories) {
            final categoryKey = categoryEntry.key;
            final categoryVal = categoryEntry.value;

            if (categoryVal is Map) {
              for (final estateEntry in categoryVal.entries) {
                final estateId = estateEntry.key;
                final estateData = estateEntry.value;

                final estateOwnerId =
                    (estateData is Map && estateData['IDUser'] != null)
                        ? estateData['IDUser'].toString()
                        : null;

                if (estateOwnerId == userId) {
                  // Delete feedback for this estate
                  if (feedbacks.isNotEmpty) {
                    for (final fbEntry in feedbacks.entries) {
                      final fbId = fbEntry.key;
                      final fbData = fbEntry.value;
                      if (fbData is Map && fbData['EstateID'] == estateId) {
                        await dbRef
                            .child('App/CustomerFeedback/$fbId')
                            .remove();
                      }
                    }
                  }

                  // Delete estate chat
                  await dbRef.child('App/EstateChats/$estateId').remove();

                  // Delete estate
                  await dbRef
                      .child('App/Estate/$categoryKey/$estateId')
                      .remove();
                }
              }
            }

            catsProcessed += 1;
            final catProgress =
                0.15 + (catsProcessed / totalCategories) * 0.35; // 0.15 -> 0.50
            updateProgress(catProgress);
          }
        }
      } else {
        updateProgress(0.50);
      }

      // 3) Delete posts (App/AllPosts where userId == current)
      final postsSnap = await dbRef.child('App/AllPosts').once();
      if (postsSnap.snapshot.value != null && postsSnap.snapshot.value is Map) {
        final posts = postsSnap.snapshot.value as Map;
        for (final postEntry in posts.entries) {
          final postId = postEntry.key;
          final postData = postEntry.value;
          if (postData is Map && postData['userId'] == userId) {
            await dbRef.child('App/AllPosts/$postId').remove();
          }
        }
      }
      updateProgress(0.65);

      // 4) Delete booking requests (App/Booking/Book where IDOwner == current)
      final bookSnap = await dbRef.child('App/Booking/Book').once();
      if (bookSnap.snapshot.value != null && bookSnap.snapshot.value is Map) {
        final bookings = bookSnap.snapshot.value as Map;
        for (final bookEntry in bookings.entries) {
          final bookId = bookEntry.key;
          final bookData = bookEntry.value;
          if (bookData is Map && bookData['IDOwner'] == userId) {
            await dbRef.child('App/Booking/Book/$bookId').remove();
          }
        }
      }
      updateProgress(0.80);

      // 5) Delete AccessPins (App/AccessPins/<userId>)
      await dbRef.child('App/AccessPins/$userId').remove();
      updateProgress(0.88);

      // 6) Delete auth account + sign out
      await user.delete();
      await FirebaseAuth.instance.signOut();
      updateProgress(1.0);

      // Close progress dialog
      Navigator.of(dialogContext).pop();

      // Return to first route (e.g., login)
      if (Navigator.of(parentContext).canPop()) {
        Navigator.of(parentContext).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close progress dialog if still open
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
            content: Text(e is FirebaseAuthException
                ? (e.message ?? 'Auth error')
                : e.toString())),
      );
    }
  }

  // -------------------- Reauth: Email/Password --------------------

  Future<void> _promptPassword(BuildContext context) async {
    final parentContext = context;
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      showDialog(
        context: parentContext,
        builder: (_) => FailureDialog(
          text: getTranslated(parentContext, "Verify Email"),
          text1:
              getTranslated(parentContext, "No account found for that email."),
        ),
      );
      return;
    }

    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        bool obscurePassword = true;
        bool obscureConfirm = true;
        bool loading = false;

        Future<void> onConfirm() async {
          final password = passwordController.text.trim();
          final confirmPassword = confirmPasswordController.text.trim();

          if (password != confirmPassword) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                  content: Text(
                      getTranslated(parentContext, 'Passwords do not match.'))),
            );
            return;
          }

          try {
            (dialogContext as Element).markNeedsBuild();
            loading = true;

            final email = user!.email!;
            final credential =
                EmailAuthProvider.credential(email: email, password: password);
            await user.reauthenticateWithCredential(credential);

            Navigator.of(dialogContext).pop(); // close password dialog
            await _showDeletionProgress(parentContext); // run deletion steps
          } on FirebaseAuthException catch (e) {
            String message = e.message ?? 'Auth error';
            if (e.code == 'wrong-password') {
              message = getTranslated(
                  parentContext, "Incorrect password. Please try again.");
              showDialog(
                context: parentContext,
                builder: (_) => const FailureDialog(
                  text: "Incorrect Password!",
                  text1: "Your password is incorrect.",
                ),
              );
            } else {
              ScaffoldMessenger.of(parentContext)
                  .showSnackBar(SnackBar(content: Text(message)));
            }
          } finally {
            loading = false;
          }
        }

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(getTranslated(parentContext, 'Confirm Password')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: getTranslated(parentContext, 'Password'),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: getTranslated(parentContext, 'Confirm Password'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(getTranslated(parentContext, 'Cancel')),
              ),
              TextButton(
                onPressed: loading ? null : onConfirm,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        getTranslated(parentContext, 'Confirm Delete'),
                        style: const TextStyle(color: Colors.red),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- Reauth: Phone OTP --------------------
  // MODIFIED PART
  Future<void> _promptPhoneOTP(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final db = FirebaseDatabase.instance;
    final parentContext = context;

    String? phoneNumber = auth.currentUser?.phoneNumber;

    // Fallback to RTDB if not linked in Auth
    if (phoneNumber == null || phoneNumber.isEmpty) {
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final snap = await db.ref("App/User/$uid/PhoneNumber").get();
        if (snap.exists && snap.value is String) {
          phoneNumber = (snap.value as String).trim();
        }
      }
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      showDialog(
        context: parentContext,
        builder: (_) => FailureDialog(
          text: getTranslated(parentContext, "Phone not found"),
          text1: getTranslated(parentContext,
              "We couldn't find a phone number linked to your account."),
        ),
      );
      return;
    }

    String? verificationId;
    bool codeSent = false;
    bool isSending = false;
    bool isVerifying = false;

    final phoneCtrl = TextEditingController(text: phoneNumber);
    final codeCtrl = TextEditingController();

    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future<void> sendCode() async {
          if (isSending) return;
          isSending = true;
          (dialogCtx as Element).markNeedsBuild();

          try {
            final phone = phoneCtrl.text.trim();
            await auth.verifyPhoneNumber(
              phoneNumber: phone,
              // verificationCompleted: (PhoneAuthCredential cred) async {
              //   try {
              //     await auth.currentUser?.reauthenticateWithCredential(cred);
              //     if (Navigator.of(dialogCtx).canPop()) {
              //       Navigator.of(dialogCtx).pop();
              //     }
              //     await _showDeletionProgress(parentContext);
              //   } catch (_) {}
              // },
              verificationCompleted: (PhoneAuthCredential cred) async {
                // ❌ DO NOTHING HERE
                // We disable automatic verification & deletion.
                // User must enter OTP manually.
              },

              verificationFailed: (FirebaseAuthException e) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(e.message ?? "Verification failed.")),
                );
              },
              codeSent: (String verId, int? resendToken) {
                verificationId = verId;
                codeSent = true;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      getTranslated(parentContext, "Code sent"),
                    ),
                  ),
                );
                isSending = false;
                (dialogCtx as Element).markNeedsBuild();
              },
              codeAutoRetrievalTimeout: (String verId) {
                verificationId = verId;
              },
              timeout: const Duration(minutes: 2),
            );
          } catch (e) {
            isSending = false;
            (dialogCtx as Element).markNeedsBuild();
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(parentContext, "Failed to send code"),
                ),
              ),
            );
          }
        }

        Future<void> verifyAndDelete() async {
          if (isVerifying) return;
          if (verificationId == null) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(parentContext, "Please request the code first"),
                ),
              ),
            );
            return;
          }

          final smsCode = codeCtrl.text.trim();
          if (smsCode.length < 4) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(parentContext, "Enter the OTP code"),
                ),
              ),
            );
            return;
          }

          isVerifying = true;
          (dialogCtx as Element).markNeedsBuild();

          try {
            final credential = PhoneAuthProvider.credential(
              verificationId: verificationId!,
              smsCode: smsCode,
            );
            await auth.currentUser?.reauthenticateWithCredential(credential);

            if (Navigator.of(dialogCtx).canPop()) {
              Navigator.of(dialogCtx).pop();
            }
            await _showDeletionProgress(parentContext);
          } on FirebaseAuthException catch (e) {
            String msg = e.message ?? "Verification failed.";
            if (e.code == 'invalid-verification-code') {
              msg = getTranslated(parentContext, "Invalid code");
            }
            ScaffoldMessenger.of(parentContext)
                .showSnackBar(SnackBar(content: Text(msg)));
          } finally {
            isVerifying = false;
            (dialogCtx as Element).markNeedsBuild();
          }
        }

        // IMPORTANT: we call sendCode immediately so the user sees the loader right away
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (!isSending && !codeSent) {
        //     sendCode();
        //   }
        // });

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(getTranslated(parentContext, "Verify Phone")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phone field (editable) — we still show it
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: getTranslated(parentContext, "Phone Number"),
                      helperText: getTranslated(parentContext,
                          "Use E.164 format, e.g. +9665XXXXXXXX"),
                    ),
                    enabled: !isSending && !codeSent,
                  ),
                  const SizedBox(height: 12),

                  // HERE: while we are sending and we still don't have the OTP field
                  if (isSending && !codeSent) ...[
                    const SizedBox(height: 4),
                    const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getTranslated(parentContext, "Sending code..."),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],

                  // Once code is sent, show OTP field
                  if (codeSent) ...[
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: getTranslated(parentContext, "OTP Code"),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(getTranslated(parentContext, "Cancel")),
                ),
                // If code is not sent yet, show "Send Code" but disabled while sending
                if (!codeSent)
                  TextButton(
                    onPressed: isSending
                        ? null
                        : () {
                            sendCode();
                            (dialogCtx as Element).markNeedsBuild();
                          },
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(getTranslated(parentContext, "Send Code")),
                  ),
                // If code sent, show "Verify & Delete"
                if (codeSent)
                  TextButton(
                    onPressed: isVerifying ? null : verifyAndDelete,
                    child: isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            getTranslated(parentContext, "Verify & Delete"),
                            style: const TextStyle(color: Colors.red),
                          ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Ask the user which reauth method to use.
  Future<void> _chooseDeletionMethod(BuildContext context) async {
    final parentContext = context;

    await showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslated(parentContext, 'Confirm Delete'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              getTranslated(
                parentContext,
                'Are you sure you want to delete your account? This action cannot be undone.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: kPurpleColor,
                child: Icon(Icons.mail, color: Colors.white),
              ),
              title: Text(getTranslated(parentContext, 'Email & Password')),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _promptPassword(parentContext);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: kPurpleColor,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: Text(getTranslated(parentContext, 'Phone number')),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _promptPhoneOTP(parentContext);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              child: Text(getTranslated(parentContext, 'Cancel')),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      appBar: ReusedAppBar(title: getTranslated(context, 'Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Language Settings
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Text(
                getTranslated(context, 'Language Settings'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPurpleColor,
                ),
              ),
            ),
            ListTile(
              title: const Text(
                'English',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kPurpleColor),
              ),
              trailing: Radio<bool>(
                value: true,
                groupValue: provider.CheckLangValue,
                onChanged: (value) async {
                  if (value == null) return;
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString('Language', 'en');
                  MyApp.setLocale(context, const Locale('en', 'SA'));
                  provider.updateLanguage(value);
                },
                activeColor: kPurpleColor,
              ),
            ),
            ListTile(
              title: const Text(
                'عربي',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kPurpleColor),
              ),
              trailing: Radio<bool>(
                value: false,
                groupValue: provider.CheckLangValue,
                onChanged: (value) async {
                  if (value == null) return;
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString('Language', 'ar');
                  MyApp.setLocale(context, const Locale('ar', 'SA'));
                  provider.updateLanguage(value);
                },
                activeColor: kPurpleColor,
              ),
            ),

            const Divider(),

            // Call Center
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Text(
                getTranslated(context, 'Call Center'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPurpleColor,
                ),
              ),
            ),
            ListTile(
              title: const Text(
                '920031542',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kPurpleColor),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.support_agent, color: kPurpleColor),
                onPressed: () => _makePhoneCall('920031542'),
              ),
            ),

            const Divider(),

            // Delete Account
            ListTile(
              title: Text(
                getTranslated(context, 'Delete Account'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              subtitle: Text(
                getTranslated(
                    context, 'Permanently delete your account and all data.'),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                onPressed: () => _chooseDeletionMethod(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
