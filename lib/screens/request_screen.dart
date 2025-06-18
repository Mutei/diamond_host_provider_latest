// request_screen.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:shimmer/shimmer.dart'; // Added for shimmer animation

import '../backend/firebase_services.dart';
import '../backend/booking_services.dart'; // Import BookingServices for updateBookingStatus (for accept flow)
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../main.dart';
import '../state_management/general_provider.dart';
import '../utils/success_dialogue.dart';
import '../widgets/booking_list_widget.dart';
import '../widgets/list_add_widget.dart';
import '../widgets/list_room_widget.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<double?> fetchAverageUserRating(String userId) async {
    DataSnapshot snap = await FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating")
        .get();
    return snap.exists ? double.tryParse(snap.value.toString()) : null;
  }

  // Helper method to build a processing dialog with a shimmer animation.
  Widget _buildProcessingDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFB3E5FC), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.blueAccent.withOpacity(0.6),
              highlightColor: Colors.blueAccent.withOpacity(0.2),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                child: Center(
                  child: Icon(
                    Icons.hourglass_empty,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslated(context, "Processing..."),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslated(context, "Please wait"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for accepting the request.
  /// For rejections, we show the rejection reason dialog instead.
  Future<void> _showConfirmationDialog(Map map, String actionType) async {
    final BuildContext activeContext = navigatorKey.currentContext!;
    if (actionType == "reject") {
      // Call the new rejection reason dialog
      await _showRejectionReasonDialog(activeContext, map);
      return;
    }

    // Accept flow
    final String message = getTranslated(
        activeContext, "Are you sure you want to accept the request?");
    final String statusUpdate = "2";
    final String actionButtonText = getTranslated(activeContext, "Confirm");

    return showDialog<void>(
      context: activeContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getTranslated(activeContext, "Confirmation")),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(getTranslated(activeContext, "Cancel")),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(actionButtonText),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Show the processing dialog with shimmer animation.
                showDialog(
                  context: activeContext,
                  barrierDismissible: false,
                  builder: (context) => _buildProcessingDialog(context),
                );
                // Perform the booking status update using the BookingServices.
                BookingServices bookingServices = BookingServices();
                await bookingServices.updateBookingStatus(
                  bookingID: map['IDBook'],
                  newStatus: statusUpdate,
                );
                Navigator.of(activeContext)
                    .pop(); // Dismiss the processing dialog.
                // Show the success dialog.
                showDialog(
                  context: activeContext,
                  barrierDismissible: false,
                  builder: (context) => SuccessDialog(
                    text: "Request Accepted",
                    text1: "The request has been accepted successfully.",
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Displays a rejection reason dialog.
  /// - For standard options, the reason is saved as a plain string.
  /// - If "Other" is selected, we save a nested object inside "RejectionReason" with keys:
  ///   "value": the string ("Other") and "details": additional user input (if any).
  Future<void> _showRejectionReasonDialog(BuildContext context, Map map) async {
    final List<String> reasons = [
      getTranslated(context, "Incorrect booking details"),
      getTranslated(context, "Unavailability of required facilities"),
      getTranslated(context, "Booking is full"),
      getTranslated(context, "Other"),
    ];
    String selectedReason = reasons[0];

    // Text controller for additional details when "Other" is selected.
    final TextEditingController otherReasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext,
              void Function(void Function()) setState) {
            return AlertDialog(
              title: Text(getTranslated(context, "Select Rejection Reason")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      );
                    }).toList(),
                    // Show a text form field when "Other" is selected.
                    if (selectedReason == getTranslated(context, "Other"))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          controller: otherReasonController,
                          maxLength: 50, // limit to 50 characters
                          decoration: InputDecoration(
                            labelText: getTranslated(context, "Please specify"),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext, rootNavigator: true).pop(),
                  child: Text(getTranslated(context, "Cancel")),
                ),
                TextButton(
                  onPressed: () async {
                    // Build the updateData map.
                    final Map<String, dynamic> updateData = {
                      "Status": "3",
                    };

                    // If "Other" was selected, store as nested object.
                    if (selectedReason == getTranslated(context, "Other")) {
                      final String otherText =
                          otherReasonController.text.trim();
                      final Map<String, dynamic> reasonMap = {
                        "value": selectedReason,
                      };
                      if (otherText.isNotEmpty) {
                        reasonMap["details"] = otherText;
                      }
                      updateData["RejectionReason"] = reasonMap;
                    } else {
                      // Otherwise, save the reason as a plain string.
                      updateData["RejectionReason"] = selectedReason;
                    }

                    // Close the dialog.
                    Navigator.of(dialogContext, rootNavigator: true).pop();

                    // Show processing dialog.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _buildProcessingDialog(context),
                    );

                    // Update the booking record.
                    final bookingRef = FirebaseDatabase.instance
                        .ref("App/Booking/Book")
                        .child(map['IDBook']);
                    await bookingRef.update(updateData);

                    // Dismiss processing dialog.
                    Navigator.of(context, rootNavigator: true).pop();

                    // Show success dialog.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => SuccessDialog(
                        text: "Request Rejected",
                        text1: "The request has been rejected successfully.",
                      ),
                    );
                  },
                  child: Text(getTranslated(context, "Confirm")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMyDialog(BuildContext context, Map map) async {
    final bookingRef =
        FirebaseDatabase.instance.ref("App/Booking/Book").child(map['IDBook']);

    // Fetch CountDays.
    final snap = await bookingRef.get();
    final int countDays =
        int.tryParse(snap.child('CountDays').value?.toString() ?? '') ?? 1;

    // Sum room prices multiplied by countDays.
    double roomsTotal = 0.0;
    final roomsSnap = await bookingRef.child('Rooms').get();
    if (roomsSnap.exists) {
      for (final child in roomsSnap.children) {
        final price =
            double.tryParse(child.child('Price').value?.toString() ?? '') ??
                0.0;
        roomsTotal += price * countDays;
      }
    }

    // Sum prices for additional services.
    double additionalTotal = 0.0;
    final addSnap = await bookingRef.child('Additional').get();
    if (addSnap.exists) {
      for (final child in addSnap.children) {
        final price =
            double.tryParse(child.child('Price').value?.toString() ?? '') ??
                0.0;
        additionalTotal += price;
      }
    }

    // Compute grand total.
    final double computedTotal = roomsTotal + additionalTotal;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Scaffold(
        appBar: AppBar(
          iconTheme: kIconTheme,
          elevation: 0,
          title: Text(
            getTranslated(context, "Request"),
            style: const TextStyle(fontSize: 15),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  text: TextSpan(
                    text: getTranslated(context, "Booking Details"),
                    style: TextStyle(
                      fontSize: 6.w,
                      fontWeight: FontWeight.bold,
                      color: kPurpleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${getTranslated(context, "Number of Days")}: $countDays',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${getTranslated(context, "Total Price")}: ${computedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                getTranslated(context, "Rooms"),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ListRoom(map['IDBook']),
              const SizedBox(height: 10),
              Text(
                getTranslated(context, "Additional Services"),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ListAdd(map['IDBook']),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text(getTranslated(context, 'Confirm')),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showConfirmationDialog(map, "accept");
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Text(
                        getTranslated(context, 'Reject'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showConfirmationDialog(map, "reject");
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Text(getTranslated(context, 'Cancel')),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMyDialogCoffe(BuildContext context, Map map) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  text: TextSpan(
                    text: getTranslated(context, "Booking Details"),
                    style: TextStyle(
                      fontSize: 6.w,
                      fontWeight: FontWeight.bold,
                      color: kPurpleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text(getTranslated(context, 'Confirm')),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showConfirmationDialog(map, "accept");
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Text(
                        getTranslated(context, 'Reject'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showConfirmationDialog(map, "reject");
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Text(getTranslated(context, 'Cancel')),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated(context, "Requests")),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Evenly distribute tabs
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.blueAccent),
                insets: EdgeInsets.symmetric(horizontal: 8),
              ),
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.black54,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: [
                Tab(
                  child: AutoSizeText(
                    getTranslated(context, "Under Process"),
                    maxLines: 1,
                    minFontSize: 10, // will shrink as needed
                    stepGranularity: 1,
                  ),
                ),
                Tab(
                  child: AutoSizeText(
                    getTranslated(context, "Booking Accepted"),
                    maxLines: 1,
                    minFontSize: 10,
                    stepGranularity: 1,
                  ),
                ),
                Tab(
                  child: AutoSizeText(
                    getTranslated(context, "Booking Rejected"),
                    maxLines: 1,
                    minFontSize: 10,
                    stepGranularity: 1,
                  ),
                ),
                Tab(
                  child: AutoSizeText(
                    getTranslated(context, "Recent Bookings"),
                    maxLines: 1,
                    minFontSize: 10,
                    stepGranularity: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BookingList(
            status: "1",
            showDialogFunction: _showMyDialog,
            showDialogCoffeFunction: _showMyDialogCoffe,
          ),
          BookingList(status: "2"),
          BookingList(status: "3"),
          BookingList(status: "recent"),
        ],
      ),
    );
  }
}
