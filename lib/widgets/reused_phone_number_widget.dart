import '../localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../constants/colors.dart';

class ReusedPhoneNumberField extends StatelessWidget {
  final Function(String) onPhoneNumberChanged;
  final String? Function(PhoneNumber?)?
      validator; // Modify to handle PhoneNumber?

  const ReusedPhoneNumberField({
    Key? key,
    required this.onPhoneNumberChanged,
    this.validator, // Include the validator for PhoneNumber?
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: IntlPhoneField(
        decoration: InputDecoration(
          labelText: getTranslated(context, 'Phone Number'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          // Set the default enabled border
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: kDeepPurpleColor), // Border color when enabled
            borderRadius: BorderRadius.circular(30),
          ),
          // Set the border color when focused
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: kDeepPurpleColor, width: 2), // Border color when focused
            borderRadius: BorderRadius.circular(30),
          ),
          // Set the border color when there's an error
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: kPurpleColor,
                width: 2), // Border color when there's an error
            borderRadius: BorderRadius.circular(30),
          ),
          // Set the border for focused error
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: kPurpleColor,
                width: 2), // Border color when focused and there's an error
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        initialCountryCode: 'SA', // Default country code
        onChanged: (phone) {
          print("📞 IntlPhoneField → completeNumber = ${phone.completeNumber}");
          print("📱 IntlPhoneField → number = ${phone.number}");
          print("🌍 IntlPhoneField → countryCode = ${phone.countryCode}");
          print(
              "⚙️ IntlPhoneField → full = ${phone.countryISOCode} ${phone.completeNumber}");

          onPhoneNumberChanged(phone.completeNumber);
        },

        validator: validator, // Add the correct validator type
      ),
    );
  }
}
