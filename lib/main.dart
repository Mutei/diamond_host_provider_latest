// lib/main.dart

import 'package:daimond_host_provider/screens/splash_screen.dart';
import 'package:daimond_host_provider/state_management/general_provider.dart';
import 'package:daimond_host_provider/utils/failure_dialogue.dart';
import 'package:daimond_host_provider/utils/success_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';

import 'localization/demo_localization.dart';
import 'localization/language_constants.dart';

import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  print('Firebase Initialized');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
        // Add other providers here if necessary
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) async {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? language = sharedPreferences.getString("Language");
    print("Language from SharedPreferences: $language");
    if (language == null || language.isEmpty) {
      state?.setLocale(newLocale);
      await sharedPreferences.setString("Language", newLocale.languageCode);
      print('New locale saved: ${newLocale.languageCode}');
    } else {
      Locale updatedLocale = Locale(language, "SA");
      state?.setLocale(updatedLocale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  late FirebaseAnalytics analytics;
  bool _dialogIsShowing = false; // Flag to prevent multiple dialogs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeFirebaseAnalytics();
    loadLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GeneralProvider>(context, listen: false);

      // Listen to subscription expiration
      provider.subscriptionExpiredStream.listen((_) {
        if (!_dialogIsShowing) {
          _dialogIsShowing = true; // Prevent multiple dialogs
          print('Subscription expired. Showing dialog.');

          showDialog(
            context: navigatorKey.currentContext!,
            builder: (context) => AlertDialog(
              title: Text(
                getTranslated(context, "Subscription Expired"),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              content: Text(
                getTranslated(context,
                    "Your subscription has expired. You have been reverted to the Star account."),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _dialogIsShowing = false;
                    });
                    print('Subscription expired dialog dismissed.');
                  },
                  child: Text(getTranslated(context, "OK")),
                ),
              ],
            ),
          ).then((_) {
            setState(() {
              _dialogIsShowing = false; // Reset the flag when dialog is closed
            });
            print('Subscription expired dialog closed.');
          });
        }
      });

      // Listen to post status changes
      provider.postStatusChangeStream.listen((event) {
        if (!_dialogIsShowing) {
          _dialogIsShowing = true;
          if (event.status == '1') {
            showDialog(
              context: navigatorKey.currentContext!,
              builder: (context) => const SuccessDialog(
                text: "Post Added Successfully",
                text1: "Your post has been approved and is now visible.",
              ),
            ).then((_) {
              setState(() {
                _dialogIsShowing = false;
              });
            });
          } else if (event.status == '2') {
            showDialog(
              context: navigatorKey.currentContext!,
              builder: (context) => const FailureDialog(
                text: "Post Rejected",
                text1: "Your post has been rejected and was not posted.",
              ),
            ).then((_) {
              setState(() {
                _dialogIsShowing = false;
              });
            });
          }
        }
      });

      // Existing chat request dialog logic remains unchanged
      provider.subscriptionExpiredStream.listen((_) {
        // Existing code...
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GeneralProvider>(context, listen: false);
      provider.postStatusChangeStream.listen((event) {
        if (!_dialogIsShowing) {
          _dialogIsShowing = true; // Prevent multiple dialogs
          if (event.status == '1') {
            showDialog(
              context: navigatorKey.currentContext!,
              builder: (context) => SuccessDialog(
                text: "Post Added Successfully",
                text1: "Your post has been approved and is now visible.",
              ),
            ).then((_) {
              setState(() {
                _dialogIsShowing = false;
              });
            });
          } else if (event.status == '2') {
            showDialog(
              context: navigatorKey.currentContext!,
              builder: (context) => FailureDialog(
                text: "Post Rejected",
                text1: "Your post has been rejected and was not posted.",
              ),
            ).then((_) {
              setState(() {
                _dialogIsShowing = false;
              });
            });
          }
        }
      });

      checkForUpdate(); // Check for updates after initialization
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initializeFirebaseAnalytics() async {
    analytics = FirebaseAnalytics.instance;
    print('Firebase Analytics Initialized');
  }

  void loadLocale() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? language = sharedPreferences.getString("Language");
    print("Loaded Locale: $language");

    if (language != null && language.isNotEmpty) {
      setLocale(Locale(language, "SA"));
    } else {
      setLocale(const Locale("en", "US"));
      await sharedPreferences.setString("Language", "en");
      print('Default locale set to English and saved.');
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Immediate update
        InAppUpdate.performImmediateUpdate().catchError((e) {
          print("Error during update: $e");
        });
      }
    } catch (e) {
      print("Failed to check for update: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      // While loading locale, show a loading indicator
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      );
    } else {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return Directionality(
            textDirection: _locale?.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Consumer<GeneralProvider>(
              builder: (context, provider, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: "Daimond Host Provider",
                  navigatorKey: navigatorKey, // Attach the navigator key here
                  theme: provider.getTheme(context),
                  locale: _locale,
                  supportedLocales: const [
                    Locale("en", "US"),
                    Locale("ar", "SA"),
                  ],
                  localizationsDelegates: const [
                    DemoLocalization.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (var supportedLocale in supportedLocales) {
                      if (supportedLocale.languageCode ==
                              locale?.languageCode &&
                          supportedLocale.countryCode == locale?.countryCode) {
                        return supportedLocale;
                      }
                    }
                    return supportedLocales.first;
                  },
                  navigatorObservers: [
                    FirebaseAnalyticsObserver(analytics: analytics),
                  ],
                  home: const SplashScreen(),
                );
              },
            ),
          );
        },
      );
    }
  }
}
