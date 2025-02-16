import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../backend/firebase_services.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';

class ProviderNotificationScreen extends StatefulWidget {
  const ProviderNotificationScreen({super.key});

  @override
  State<ProviderNotificationScreen> createState() =>
      _ProviderNotificationScreenState();
}

class _ProviderNotificationScreenState
    extends State<ProviderNotificationScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<Map<String, dynamic>> estateNotifications = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _firebaseServices
        .setupEstateStatusListener(); // Initialize background listener
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Clear the notifications list at the beginning of the function to avoid duplicates
    estateNotifications.clear();
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("App").child("Estate");

    List<String> estateTypes = ["Coffee", "Hottel", "Restaurant"];
    List<Map<String, dynamic>> notifications = [];

    for (String estateType in estateTypes) {
      ref
          .child(estateType)
          .orderByChild("IDUser")
          .equalTo(userId)
          .onValue
          .listen((event) async {
        DataSnapshot snapshot = event.snapshot;

        for (var estateSnapshot in snapshot.children) {
          Map<String, dynamic> estateData =
              Map<String, dynamic>.from(estateSnapshot.value as Map);
          String estateStatus = estateData['IsAccepted'] ?? '1';
          String estateNameAr = estateData['NameAr'];
          String estateNameEn = estateData['NameEn'];
          String estateId = estateSnapshot.key ?? '';

          // Check if the notification already exists in the list to prevent duplicates
          bool alreadyExists =
              notifications.any((notif) => notif['estateId'] == estateId);
          if (!alreadyExists) {
            notifications.add({
              "estateId": estateId,
              "nameAr": estateNameAr,
              "nameEn": estateNameEn,
              "status": estateStatus,
            });

            // Send notification if necessary
            await _firebaseServices.checkAndSendNotification(
                estateId, estateType, estateData, estateStatus);
          }
        }

        // Update the state only once with the filtered notifications
        setState(() {
          estateNotifications = notifications;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated(context, 'Provider Notifications'),
          style: TextStyle(color: kDeepPurpleColor),
        ),
        centerTitle: true,
        iconTheme: kIconTheme,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: estateNotifications.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: estateNotifications.length,
                itemBuilder: (context, index) {
                  String estateName =
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? estateNotifications[index]["nameAr"]
                          : estateNotifications[index]["nameEn"];
                  String estateStatus = estateNotifications[index]["status"];

                  String statusText;
                  Color statusColor;

                  switch (estateStatus) {
                    case "2":
                      statusText = getTranslated(context, "Accepted");
                      statusColor = Colors.green;
                      break;
                    case "3":
                      statusText = getTranslated(context, "Rejected");
                      statusColor = Colors.red;
                      break;
                    default:
                      statusText = getTranslated(context, "Under Process");
                      statusColor = Colors.orange;
                      break;
                  }

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(estateName),
                      subtitle: Row(
                        children: [
                          Text(
                            getTranslated(context, "Status"),
                            style: TextStyle(color: statusColor),
                          ),
                          Text(": $statusText",
                              style: TextStyle(color: statusColor)),
                        ],
                      ),
                      trailing: Icon(Icons.notifications, color: statusColor),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
