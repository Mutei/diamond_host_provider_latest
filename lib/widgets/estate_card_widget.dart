import 'dart:io';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/styles.dart';

class EstateCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final double rating;
  final String typeAccount;

  const EstateCard({
    super.key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.rating,
    required this.typeAccount,
  });

  Future<File> _getCachedImage(String estateId) async {
    final directory = await getTemporaryDirectory();
    final storageRef = FirebaseStorage.instance.ref().child(estateId);
    final listResult = await storageRef.listAll();

    if (listResult.items.isEmpty) {
      throw Exception("No image found for estate: $estateId");
    }

    // pick the first image under that folder
    final firstImageRef = listResult.items.first;

    // include the actual filename in our cache key:
    final fileName = '${estateId}_${firstImageRef.name}';
    final filePath = '${directory.path}/$fileName';
    final cachedImage = File(filePath);

    try {
      if (await cachedImage.exists()) {
        // compare file‐system timestamp vs. storage metadata.updated
        DateTime lastModified = await cachedImage.lastModified();
        final metadata = await firstImageRef.getMetadata();

        if (metadata.updated != null &&
            metadata.updated!.isAfter(lastModified)) {
          await cachedImage.delete();
        } else {
          return cachedImage;
        }
      }

      // download fresh
      final imageUrl = await firstImageRef.getDownloadURL();
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        await cachedImage.writeAsBytes(response.bodyBytes);
        return cachedImage;
      } else {
        throw Exception("Failed to download image");
      }
    } catch (e) {
      throw Exception("Error loading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF193945)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<File>(
              future: _getCachedImage(estateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        color: Colors.grey[200],
                      ),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kEstatesTextsColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (typeAccount == '2' || typeAccount == '3') ...[
                        5.kW,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
