// lib/main.dart

import 'dart:async';

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

// NEW: FCM + Auth + RTDB
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'localization/demo_localization.dart';
import 'localization/language_constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // iOS/macOS foreground notification display behavior
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> setLocale(BuildContext context, Locale newLocale) async {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    final prefs = await SharedPreferences.getInstance();
    final String? language = prefs.getString("Language");

    if (language == null || language.isEmpty) {
      state?.setLocale(newLocale);
      await prefs.setString("Language", newLocale.languageCode);
    } else {
      final Locale updatedLocale = Locale(language, "SA");
      state?.setLocale(updatedLocale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  late FirebaseAnalytics _analytics;
  bool _dialogIsShowing = false;

  // NEW: cancelable token listener
  StreamSubscription<String>? _tokenSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFirebaseAnalytics();
    _loadLocale();
    _initPushNotifications();

    // Wire provider listeners after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GeneralProvider>(context, listen: false);

      // Subscription expired dialog
      provider.subscriptionExpiredStream.listen((_) {
        if (_dialogIsShowing) return;
        _dialogIsShowing = true;

        showDialog(
          context: navigatorKey.currentContext!,
          builder: (ctx) => AlertDialog(
            title: Text(
              getTranslated(ctx, "Subscription Expired"),
              style: TextStyle(color: Theme.of(ctx).primaryColor),
            ),
            content: Text(
              getTranslated(
                ctx,
                "Your subscription has expired. You have been reverted to the Star account.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _dialogIsShowing = false);
                },
                child: Text(getTranslated(ctx, "OK")),
              ),
            ],
          ),
        ).then((_) => setState(() => _dialogIsShowing = false));
      });

      // Post status changes
      provider.postStatusChangeStream.listen((event) {
        if (_dialogIsShowing) return;
        _dialogIsShowing = true;

        final Widget dialog = (event.status == '1')
            ? const SuccessDialog(
                text: "Post Added Successfully",
                text1: "Your post has been approved and is now visible.",
              )
            : const FailureDialog(
                text: "Post Rejected",
                text1: "Your post has been rejected and was not posted.",
              );

        showDialog(
          context: navigatorKey.currentContext!,
          builder: (ctx) => dialog,
        ).then((_) => setState(() => _dialogIsShowing = false));
      });

      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenSub?.cancel();
    super.dispose();
  }

  void _initializeFirebaseAnalytics() {
    _analytics = FirebaseAnalytics.instance;
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? language = prefs.getString("Language");

    if (language != null && language.isNotEmpty) {
      setLocale(Locale(language, "SA"));
    } else {
      setLocale(const Locale("en", "US"));
      await prefs.setString("Language", "en");
    }
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // log only
      debugPrint("In-app update check error: $e");
    }
  }

  /// ======== NEW: Notifications bootstrap ========
  Future<void> _initPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS/macOS + Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint('Notification authorization: ${settings.authorizationStatus}');

      // Ensure banner while in foreground (Apple)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Save current token
      await _saveCurrentToken();

      // Keep token fresh
      _tokenSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        debugPrint('FCM token refreshed: $token');
        await _persistToken(token);
      });

      // Optional: foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        debugPrint(
            'Foreground message: ${m.notification?.title} | ${m.notification?.body}');
      });
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  Future<void> _saveCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _persistToken(token);
      }
    } catch (e) {
      debugPrint('Get token error: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Not signed in yet; you can call _saveCurrentToken() after login too.
      return;
    }

    // Legacy single token path (kept for compatibility with your codebase)
    await FirebaseDatabase.instance.ref('App/User/$uid/Token').set(token);

    // Device-scoped path for multi-device support
    final ref = FirebaseDatabase.instance.ref('App/User/$uid/Tokens/$token');
    await ref.update(<String, dynamic>{
      'createdAt': ServerValue.timestamp,
      'platform': 'flutter',
      'active': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Directionality(
          textDirection: _locale!.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Consumer<GeneralProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: "Daimond Host Provider",
                navigatorKey: navigatorKey,
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
                  for (final supported in supportedLocales) {
                    if (supported.languageCode == locale?.languageCode &&
                        supported.countryCode == locale?.countryCode) {
                      return supported;
                    }
                  }
                  return supportedLocales.first;
                },
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: _analytics),
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
