import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_localization.dart';

const String language = 'languageCode';

//languages code
const String english = 'en';
const String arabic = 'ar';
const String nulls = 'null';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(language, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString(language) ?? "en";
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case english:
      return const Locale(english, 'US');
    case arabic:
      return const Locale(arabic, "SA");
    default:
      return const Locale(english, 'US');
  }
}

String getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)?.translate(key) ?? nulls;
}
