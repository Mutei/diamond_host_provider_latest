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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reauthenticate user with provided password
      final email = user.email!;
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      final userId = user.uid;
      final dbRef = FirebaseDatabase.instance.ref();

      // Delete user info
      await dbRef.child("App/User/$userId").remove();

      // Delete estates and associated feedback and chats
      DatabaseEvent estateEvent = await dbRef.child("App/Estate").once();
      if (estateEvent.snapshot.value != null) {
        Map estates = estateEvent.snapshot.value as Map;
        for (var categoryEntry in estates.entries) {
          var category = categoryEntry.key;
          var items = categoryEntry.value;
          if (items is Map) {
            for (var estateEntry in items.entries) {
              var estateId = estateEntry.key;
              var estateData = estateEntry.value;
              if (estateData['IDUser'] == userId) {
                // Delete feedback for this estate
                DatabaseEvent feedbackEvent =
                    await dbRef.child("App/CustomerFeedback").once();
                if (feedbackEvent.snapshot.value != null) {
                  Map feedbacks = feedbackEvent.snapshot.value as Map;
                  for (var feedbackEntry in feedbacks.entries) {
                    var feedbackId = feedbackEntry.key;
                    var feedbackData = feedbackEntry.value;
                    if (feedbackData['EstateID'] == estateId) {
                      await dbRef
                          .child("App/CustomerFeedback/$feedbackId")
                          .remove();
                    }
                  }
                }

                // Delete estate chat for this estate
                await dbRef.child("App/EstateChats/$estateId").remove();

                // Delete the estate
                await dbRef.child("App/Estate/$category/$estateId").remove();
              }
            }
          }
        }
      }

      // Delete posts
      DatabaseEvent postsEvent = await dbRef.child("App/AllPosts").once();
      if (postsEvent.snapshot.value != null) {
        Map posts = postsEvent.snapshot.value as Map;
        for (var postEntry in posts.entries) {
          var postId = postEntry.key;
          var postData = postEntry.value;
          if (postData['userId'] == userId) {
            await dbRef.child("App/AllPosts/$postId").remove();
          }
        }
      }

      // Delete booking requests
      DatabaseEvent bookingEvent = await dbRef.child("App/Booking/Book").once();
      if (bookingEvent.snapshot.value != null) {
        Map bookings = bookingEvent.snapshot.value as Map;
        for (var bookingEntry in bookings.entries) {
          var bookId = bookingEntry.key;
          var bookData = bookingEntry.value;
          if (bookData['IDOwner'] == userId) {
            await dbRef.child("App/Booking/Book/$bookId").remove();
          }
        }
      }

      // Delete user authentication account
      await user.delete();

      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Navigate to the initial screen (e.g., login page)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print(e);
      if (e is FirebaseAuthException && e.code == 'wrong-password') {
        showDialog(
          context: context,
          builder: (context) => const FailureDialog(
            text: "Incorrect Password!",
            text1: "Your password is incorrect.",
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated(context, "Error deleting account")),
          ),
        );
      }
    }
  }

  Future<void> _promptPassword(BuildContext context) async {
    final parentContext = context;
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(getTranslated(parentContext, "Confirm Password")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: getTranslated(parentContext, "Password"),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: getTranslated(parentContext, "Confirm Password"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(getTranslated(parentContext, "Cancel")),
          ),
          TextButton(
            onPressed: () async {
              String password = passwordController.text;
              String confirmPassword = confirmPasswordController.text;
              if (password != confirmPassword) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      getTranslated(parentContext, "Passwords do not match."),
                    ),
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop(); // Close password dialog

              // Show progress indicator before starting deletion
              showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Attempt to delete account
              await _deleteAccount(parentContext, password);

              // No need for extra pop here as _deleteAccount handles navigation and progress dialog is dismissed by popUntil.
            },
            child: Text(
              getTranslated(parentContext, "Confirm Delete"),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Language Settings Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Text(
                getTranslated(context, "Language Settings"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPurpleColor,
                ),
              ),
            ),
            ListTile(
              title: const Text(
                "English",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kPurpleColor,
                ),
              ),
              trailing: Radio<bool>(
                value: true,
                groupValue: provider.CheckLangValue,
                onChanged: (value) async {
                  if (value != null) {
                    SharedPreferences sharedPreferences =
                        await SharedPreferences.getInstance();
                    sharedPreferences.setString("Language", "en");
                    Locale newLocale = const Locale("en", "SA");
                    MyApp.setLocale(context, newLocale);
                    provider.updateLanguage(value);
                  }
                },
                activeColor: kPurpleColor,
              ),
            ),
            ListTile(
              title: const Text(
                "عربي",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kPurpleColor,
                ),
              ),
              trailing: Radio<bool>(
                value: false,
                groupValue: provider.CheckLangValue,
                onChanged: (value) async {
                  if (value != null) {
                    SharedPreferences sharedPreferences =
                        await SharedPreferences.getInstance();
                    sharedPreferences.setString("Language", "ar");
                    Locale newLocale = const Locale("ar", "SA");
                    MyApp.setLocale(context, newLocale);
                    provider.updateLanguage(value);
                  }
                },
                activeColor: kPurpleColor,
              ),
            ),
            // const Divider(),
            //
            // // Theme Settings Section
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            //   child: Text(
            //     getTranslated(context, "Theme Settings"),
            //     style: const TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //       color: kPurpleColor,
            //     ),
            //   ),
            // ),
            //
            // ListTile(
            //   title: Text(
            //     getTranslated(context, "Light Mode"),
            //     style: const TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w500,
            //       color: kPurpleColor,
            //     ),
            //   ),
            //   trailing: Radio<ThemeModeType>(
            //     value: ThemeModeType.light,
            //     groupValue: provider.themeMode,
            //     onChanged: (value) {
            //       provider.toggleTheme(ThemeModeType.light);
            //     },
            //     activeColor: kPurpleColor,
            //   ),
            // ),
            // ListTile(
            //   title: Text(
            //     getTranslated(context, "Dark Mode"),
            //     style: const TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w500,
            //       color: kPurpleColor,
            //     ),
            //   ),
            //   trailing: Radio<ThemeModeType>(
            //     value: ThemeModeType.dark,
            //     groupValue: provider.themeMode,
            //     onChanged: (value) {
            //       provider.toggleTheme(ThemeModeType.dark);
            //     },
            //     activeColor: kPurpleColor,
            //   ),
            // ),
            // ListTile(
            //   title: Text(
            //     getTranslated(context, "System Mode"),
            //     style: const TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w500,
            //       color: kPurpleColor,
            //     ),
            //   ),
            //   trailing: Radio<ThemeModeType>(
            //     value: ThemeModeType.system,
            //     groupValue: provider.themeMode,
            //     onChanged: (value) {
            //       provider.toggleTheme(ThemeModeType.system);
            //     },
            //     activeColor: kPurpleColor,
            //   ),
            // ),
            const Divider(),

            // Call Center Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Text(
                getTranslated(context, "Call Center"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPurpleColor,
                ),
              ),
            ),
            ListTile(
              title: const Text(
                "920031542",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kPurpleColor,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.support_agent, color: kPurpleColor),
                onPressed: () => _makePhoneCall("920031542"),
              ),
            ),
            const Divider(),

            // Delete Account Section
            ListTile(
              title: Text(
                getTranslated(context, "Delete Account"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                getTranslated(
                    context, "Permanently delete your account and all data."),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                onPressed: () {
                  final parentContext = context;
                  showDialog(
                    context: parentContext,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Column(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 50, color: Colors.red),
                          const SizedBox(height: 10),
                          Text(
                            getTranslated(parentContext, "Confirm Delete"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        getTranslated(parentContext,
                            "Are you sure you want to delete your account? This action cannot be undone."),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      actionsAlignment: MainAxisAlignment.spaceEvenly,
                      actions: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.cancel, color: Colors.black54),
                          label: Text(getTranslated(parentContext, "Cancel")),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await _promptPassword(parentContext);
                          },
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.white),
                          label: Text(getTranslated(parentContext, "Delete")),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
