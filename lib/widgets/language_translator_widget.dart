import 'package:daimond_host_provider/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/language_constants.dart'; // Import your localization file
import '../main.dart'; // Import the main app file for locale handling
import '../constants/colors.dart'; // Import color constants
import '../state_management/general_provider.dart'; // Import your provider

class LanguageDialogWidget extends StatelessWidget {
  const LanguageDialogWidget({Key? key}) : super(key: key);

  Future<void> _changeLanguage(
      BuildContext context, String languageCode, String countryCode) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("Language", languageCode);
    Locale newLocale = Locale(languageCode, countryCode);
    MyApp.setLocale(context, newLocale);

    bool isEnglish = languageCode == "en";
    Provider.of<GeneralProvider>(context, listen: false)
        .updateLanguage(isEnglish);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        getTranslated(context, "Choose Language"),
        style: kTeritary,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              getTranslated(context, 'English'),
              style: kSecondaryStyle,
            ),
            onTap: () => _changeLanguage(context, "en", "SA"),
          ),
          ListTile(
            title: Text(
              getTranslated(context, 'Arabic'),
              style: kSecondaryStyle,
            ),
            onTap: () => _changeLanguage(context, "ar", "SA"),
          ),
        ],
      ),
    );
  }
}
