import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';

class BookingCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Animation<double> animation;
  final String estateName; // Add this to receive the translated name

  const BookingCardWidget({
    Key? key,
    required this.booking,
    required this.animation,
    required this.estateName, // Add this to the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation.drive(Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOut))),
      child: GestureDetector(
        onTap: () {
          // Add any interaction or additional navigation if necessary
        },
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${getTranslated(context, 'Booking ID')}: ${booking["bookingId"]}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPurpleColor,
                  ),
                ),
                12.kH,
                _buildStatusWidget(context, booking["status"]),
                12.kH,
                _buildInfoRow(context, Icons.store,
                    '${getTranslated(context, 'Name')}: $estateName'), // Display the translated estate name
                12.kH,
                _buildInfoRow(context, Icons.date_range,
                    '${getTranslated(context, 'Date')}: ${booking["startDate"]}'),
                12.kH,
                _buildInfoRow(context, Icons.access_time,
                    '${getTranslated(context, 'Time')}: ${booking["clock"]}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Status widget based on the booking status
  Widget _buildStatusWidget(BuildContext context, String status) {
    IconData icon;
    Color iconColor;
    String statusText;

    switch (status) {
      case '1':
        icon = Icons.hourglass_top;
        iconColor = Colors.orange;
        statusText = getTranslated(context, 'Your booking is under progress.');
        break;
      case '2':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = getTranslated(context, 'Booking Accepted');
        break;
      case '3':
        icon = Icons.cancel;
        iconColor = Colors.red;
        statusText = getTranslated(context, 'Booking Rejected');
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        statusText = getTranslated(context, 'Unknown Status');
    }

    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 10),
        Text(
          statusText,
          style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Helper method to create an icon and text row
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: kPurpleColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: kSecondaryStyle,
        ),
      ],
    );
  }
}
