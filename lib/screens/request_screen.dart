// request_screen.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // NEW
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../backend/firebase_services.dart';
import '../backend/booking_services.dart';
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

  // Scope for this device (null => ALL estates)
  bool _scopeLoaded = false;
  String? _filterEstateId;

  @override
  void initState() {
    super.initState();
    Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();
    _tabController = TabController(length: 4, vsync: this);
    _loadDeviceScope();
  }

  Future<void> _loadDeviceScope() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseMessaging.instance.getToken();

      if (uid == null || token == null) {
        setState(() {
          _filterEstateId = null;
          _scopeLoaded = true;
        });
        return;
      }

      final scopeRef =
          FirebaseDatabase.instance.ref('App/User/$uid/Tokens/$token/scope');
      final snap = await scopeRef.get();

      if (!snap.exists) {
        setState(() {
          _filterEstateId = null; // default: owner/all
          _scopeLoaded = true;
        });
        return;
      }

      final type = snap.child('type').value?.toString();
      if (type == 'estate') {
        final estId = snap.child('estateId').value?.toString();
        setState(() {
          _filterEstateId = (estId != null && estId.isNotEmpty) ? estId : null;
          _scopeLoaded = true;
        });
      } else {
        setState(() {
          _filterEstateId = null;
          _scopeLoaded = true;
        });
      }
    } catch (_) {
      setState(() {
        _filterEstateId = null;
        _scopeLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                child: const Center(
                  child: Icon(Icons.hourglass_empty,
                      color: Colors.white, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslated(context, "Processing..."),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslated(context, "Please wait"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(Map map, String actionType) async {
    final BuildContext activeContext = navigatorKey.currentContext!;
    if (actionType == "reject") {
      await _showRejectionReasonDialog(activeContext, map);
      return;
    }

    final String message = getTranslated(
        activeContext, "Are you sure you want to accept the request?");
    const String statusUpdate = "2";
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
                showDialog(
                  context: activeContext,
                  barrierDismissible: false,
                  builder: (context) => _buildProcessingDialog(context),
                );
                BookingServices bookingServices = BookingServices();
                await bookingServices.updateBookingStatus(
                  bookingID: map['IDBook'],
                  newStatus: statusUpdate,
                );
                Navigator.of(activeContext).pop();
                showDialog(
                  context: activeContext,
                  barrierDismissible: false,
                  builder: (context) => const SuccessDialog(
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

  Future<void> _showRejectionReasonDialog(BuildContext context, Map map) async {
    final List<String> reasons = [
      getTranslated(context, "Incorrect booking details"),
      getTranslated(context, "Unavailability of required facilities"),
      getTranslated(context, "Booking is full"),
      getTranslated(context, "Other"),
    ];
    String selectedReason = reasons[0];
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
                    ...reasons.map((reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) =>
                              setState(() => selectedReason = value!),
                        )),
                    if (selectedReason == getTranslated(context, "Other"))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          controller: otherReasonController,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            labelText: "Please specify",
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
                    final Map<String, dynamic> updateData = {"Status": "3"};
                    if (selectedReason == getTranslated(context, "Other")) {
                      final String otherText =
                          otherReasonController.text.trim();
                      final Map<String, dynamic> reasonMap = {
                        "value": selectedReason
                      };
                      if (otherText.isNotEmpty)
                        reasonMap["details"] = otherText;
                      updateData["RejectionReason"] = reasonMap;
                    } else {
                      updateData["RejectionReason"] = selectedReason;
                    }

                    Navigator.of(dialogContext, rootNavigator: true).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _buildProcessingDialog(context),
                    );

                    final bookingRef = FirebaseDatabase.instance
                        .ref("App/Booking/Book")
                        .child(map['IDBook']);
                    await bookingRef.update(updateData);

                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const SuccessDialog(
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

  @override
  Widget build(BuildContext context) {
    Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();

    if (!_scopeLoaded) {
      // Keep your app bar & tabs look while scope loads
      return Scaffold(
        appBar: AppBar(
          title: Text(getTranslated(context, "Requests")),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
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
                          minFontSize: 10,
                          stepGranularity: 1)),
                  Tab(
                      child: AutoSizeText(
                          getTranslated(context, "Booking Accepted"),
                          maxLines: 1,
                          minFontSize: 10,
                          stepGranularity: 1)),
                  Tab(
                      child: AutoSizeText(
                          getTranslated(context, "Booking Rejected"),
                          maxLines: 1,
                          minFontSize: 10,
                          stepGranularity: 1)),
                  Tab(
                      child: AutoSizeText(
                          getTranslated(context, "Recent Bookings"),
                          maxLines: 1,
                          minFontSize: 10,
                          stepGranularity: 1)),
                ],
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Keys include current filter to avoid "stream already listened"
    final k1 = ValueKey('req-1-${_filterEstateId ?? "all"}');
    final k2 = ValueKey('req-2-${_filterEstateId ?? "all"}');
    final k3 = ValueKey('req-3-${_filterEstateId ?? "all"}');
    final k4 = ValueKey('req-r-${_filterEstateId ?? "all"}');

    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated(context, "Requests")),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
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
                    child: AutoSizeText(getTranslated(context, "Under Process"),
                        maxLines: 1, minFontSize: 10, stepGranularity: 1)),
                Tab(
                    child: AutoSizeText(
                        getTranslated(context, "Booking Accepted"),
                        maxLines: 1,
                        minFontSize: 10,
                        stepGranularity: 1)),
                Tab(
                    child: AutoSizeText(
                        getTranslated(context, "Booking Rejected"),
                        maxLines: 1,
                        minFontSize: 10,
                        stepGranularity: 1)),
                Tab(
                    child: AutoSizeText(
                        getTranslated(context, "Recent Bookings"),
                        maxLines: 1,
                        minFontSize: 10,
                        stepGranularity: 1)),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BookingList(
            key: k1,
            status: "1",
            filterEstateId: _filterEstateId, // NEW
            showDialogFunction: _showMyDialog,
            showDialogCoffeFunction: _showMyDialogCoffe,
          ),
          BookingList(
            key: k2,
            status: "2",
            filterEstateId: _filterEstateId,
          ),
          BookingList(
            key: k3,
            status: "3",
            filterEstateId: _filterEstateId,
          ),
          BookingList(
            key: k4,
            status: "recent",
            filterEstateId: _filterEstateId,
          ),
        ],
      ),
    );
  }

  // unchanged helper dialogs (your _showMyDialog & _showMyDialogCoffe)...
  Future<void> _showMyDialog(BuildContext context, Map map) async {
    final bookingRef =
        FirebaseDatabase.instance.ref("App/Booking/Book").child(map['IDBook']);

    final snap = await bookingRef.get();
    final int countDays =
        int.tryParse(snap.child('CountDays').value?.toString() ?? '') ?? 1;

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
}
