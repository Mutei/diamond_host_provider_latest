import 'package:daimond_host_provider/screens/fill_info_screen.dart';
import 'package:daimond_host_provider/screens/main_screen.dart';
import 'package:daimond_host_provider/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final uid = snapshot.data!.uid;

          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('App/User/$uid').get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // If DB missing -> sign out (prevents phone-only sessions going Main)
              if (!userSnap.hasData ||
                  !userSnap.data!.exists ||
                  userSnap.data!.value is! Map) {
                FirebaseAuth.instance.signOut();
                return const WelcomeScreen();
              }

              final data =
                  Map<String, dynamic>.from(userSnap.data!.value as Map);

              final typeUser = (data['TypeUser'] ?? '').toString().trim();
              final typeAccount = (data['TypeAccount'] ?? '').toString().trim();
              final onboardingDone = (data['OnboardingCompleted'] == true);

              // Hard block: empty / missing roles => no Main
              if (typeUser.isEmpty || typeAccount.isEmpty) {
                FirebaseAuth.instance.signOut();
                return const WelcomeScreen();
              }

              // If onboarding not completed -> must fill info
              if (!onboardingDone) {
                return const FillInfoScreen();
              }

              return const MainScreen();
            },
          );
        } else {
          return const WelcomeScreen();
        }

        // // else if (snapshot.hasData) {
        // //   return const MainScreen();
        // // }
        // else {
        //   return const WelcomeScreen();
        // }
      },
    );
  }
}
