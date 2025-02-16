import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/styles.dart';

class QRImage extends StatelessWidget {
  final String userId;
  final String userName;
  final String estateId;

  const QRImage(
      {required this.userId,
      required this.userName,
      required this.estateId,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData =
        'MyApp://chat?estateId=$estateId&userId=$userId&userName=$userName';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: kIconTheme,
      ),
      body: Center(
        child: QrImageView(
          backgroundColor: Colors.white,
          data: qrData,
          size: 280,
          embeddedImageStyle: QrEmbeddedImageStyle(
            size: const Size(100, 100),
          ),
        ),
      ),
    );
  }
}
