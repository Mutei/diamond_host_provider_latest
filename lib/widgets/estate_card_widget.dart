import 'dart:io';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/styles.dart';

class EstateCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final double rating;
  final String typeAccount; // Add rating parameter

  const EstateCard(
      {super.key,
      required this.nameEn,
      required this.nameAr,
      required this.estateId,
      required this.rating,
      required this.typeAccount // Pass rating to the constructor
      });

  Future<File> _getCachedImage(String estateId) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$estateId.jpg';
    final cachedImage = File(filePath);
    if (await cachedImage.exists()) {
      return cachedImage;
    }

    final storageRef = FirebaseStorage.instance.ref().child('$estateId/0.jpg');
    final imageUrl = await storageRef.getDownloadURL();
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      await cachedImage.writeAsBytes(response.bodyBytes);
    }
    return cachedImage;
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF193945)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estate Image
            FutureBuilder<File>(
              future: _getCachedImage(estateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                } else {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      image: DecorationImage(
                        image: FileImage(snapshot.data!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display estate name based on the current language
                  Row(
                    children: [
                      Text(
                        displayName,
                        // style: kSecondaryStyle,
                        style: const TextStyle(
                          color: kEstatesTextsColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (typeAccount == '2' || typeAccount == '3') ...[
                        5.kW,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeAccount == '2'
                                ? kPremiumTextColor.withOpacity(0.1)
                                : kPremiumPlusTextColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: typeAccount == '2'
                                  ? kPremiumTextColor
                                  : kPremiumPlusTextColor,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                getTranslated(
                                  context,
                                  typeAccount == '2'
                                      ? "(Premium)"
                                      : "(Premium plus)",
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeAccount == '2'
                                      ? kPremiumTextColor
                                      : kPremiumPlusTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              typeAccount == "2"
                                  ? const FaIcon(
                                      FontAwesomeIcons.medal,
                                      color: kPremiumTextColor,
                                      size: 12,
                                    )
                                  : const FaIcon(
                                      FontAwesomeIcons.trophy,
                                      color: kPremiumPlusTextColor,
                                      size: 12,
                                    ),
                            ],
                          ),
                        ),
                        // if (typeAccount == '2' || typeAccount == '3') ...[
                        //   typeAccount == "2"
                        //       ? const FaIcon(
                        //           FontAwesomeIcons.medal,
                        //           color: kPremiumTextColor,
                        //           size: 10,
                        //         )
                        //       : const FaIcon(
                        //           FontAwesomeIcons.trophy,
                        //           color: kPremiumPlusTextColor,
                        //           size: 10,
                        //         ),
                        // ]
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Rating, Fee, and Time info
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1), // Display dynamic rating
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // const SizedBox(width: 10),
                      // const Icon(Icons.monetization_on,
                      //     color: Colors.grey, size: 16),
                      // const SizedBox(width: 4),
                      // const Text(
                      //   "Free", // Replace with dynamic fee data
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                      // const SizedBox(width: 10),
                      // const Icon(Icons.timer, color: Colors.grey, size: 16),
                      // const SizedBox(width: 4),
                      // const Text(
                      //   "20 min", // Replace with dynamic time data
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
