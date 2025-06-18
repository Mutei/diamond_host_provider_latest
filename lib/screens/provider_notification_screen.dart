import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../backend/firebase_services.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/rooms.dart';
import 'edit_estate_hotel_screen.dart';
import 'edit_estate_screen.dart';
import 'profile_estate_screen.dart';

class ProviderNotificationScreen extends StatefulWidget {
  const ProviderNotificationScreen({Key? key}) : super(key: key);

  @override
  _ProviderNotificationScreenState createState() =>
      _ProviderNotificationScreenState();
}

class _ProviderNotificationScreenState
    extends State<ProviderNotificationScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<Map<String, dynamic>> estateNotifications = [];
  String? userId;
  bool isLoading = true;
  List<Rooms> LstRooms = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    // Initialize any background listener if needed
    _firebaseServices.setupEstateStatusListener();
    _loadNotifications();
  }

  /// Fetch notifications for a given estate type, storing all data.
  Future<List<Map<String, dynamic>>> _fetchNotificationsForType(
      String estateType) async {
    List<Map<String, dynamic>> notifications = [];
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("App/Estate").child(estateType);

    try {
      final snapshot = await ref.get();
      if (snapshot.exists) {
        for (DataSnapshot child in snapshot.children) {
          final estateData = Map<String, dynamic>.from(child.value as Map);

          // Filter by user ID
          if (estateData['IDUser'] != userId) continue;

          // Extract the estate status (IsAccepted field)
          String estateStatus = estateData['IsAccepted']?.toString() ?? '1';

          // Add all fields from the DB + child key as 'estateId'
          final fullEstate = {
            ...estateData, // Spread all DB fields
            'estateId': child.key, // Keep the child key
            'status': estateStatus, // For convenience in the UI
          };

          notifications.add(fullEstate);

          // Optionally send a notification if required
          await _firebaseServices.checkAndSendNotification(
            child.key ?? '',
            estateType,
            estateData,
            estateStatus,
          );
        }
      }
    } catch (e) {
      print("Error fetching notifications for $estateType: $e");
    }
    return notifications;
  }

  /// Load all notifications concurrently for the different estate types.
  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      estateNotifications.clear();
    });

    List<String> estateTypes = ["Coffee", "Hottel", "Restaurant"];
    List<Future<List<Map<String, dynamic>>>> futures =
        estateTypes.map((type) => _fetchNotificationsForType(type)).toList();

    try {
      List<List<Map<String, dynamic>>> results = await Future.wait(futures);
      // Flatten the lists
      List<Map<String, dynamic>> allNotifications = [];
      for (var list in results) {
        allNotifications.addAll(list);
      }

      // Remove duplicates if necessary
      final uniqueNotifications = <String, Map<String, dynamic>>{};
      for (var notif in allNotifications) {
        uniqueNotifications[notif['estateId']] = notif;
      }

      setState(() {
        estateNotifications = uniqueNotifications.values.toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading notifications: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Builds a card to display each estate's notification and handles navigation.
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // Decide which name to show based on the current language
    String estateName = Localizations.localeOf(context).languageCode == 'ar'
        ? (notification["NameAr"] ?? '')
        : (notification["NameEn"] ?? '');

    // The status we set above
    String estateStatus = notification["status"] ?? '1';

    String statusText;
    Color statusColor;
    IconData statusIcon;
    switch (estateStatus) {
      case "2":
        statusText = getTranslated(context, "Accepted");
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case "3":
        statusText = getTranslated(context, "Rejected");
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = getTranslated(context, "Under Process");
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          estateName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                "${getTranslated(context, "Status")}: ",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(color: statusColor),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: statusColor),
        onTap: () {
          // If estate is accepted
          if (estateStatus == "2") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileEstateScreen(
                  nameEn: notification['NameEn'] ?? '',
                  nameAr: notification['NameAr'] ?? '',
                  estateId: notification['estateId'] ?? '',
                  estateType: notification['Type'] ?? '',
                  location: notification['Location'] ?? '',
                  rating: double.tryParse(
                          notification['Rating']?.toString() ?? '0') ??
                      0,
                  fee: notification['Fee'] ?? '',
                  deliveryTime: notification['Time'] ?? '',
                  price: 0.0, // Adjust if you have a real price
                  typeOfRestaurant: notification['TypeofRestaurant'] ?? '',
                  bioEn: notification['BioEn'] ?? '',
                  bioAr: notification['BioAr'] ?? '',
                  sessions: notification['Sessions'] ?? '',
                  menuLink: notification['MenuLink'] ?? '',
                  entry: notification['Entry'] ?? '',
                  music: notification['Lstmusic'] ?? '',
                  lat:
                      double.tryParse(notification['Lat']?.toString() ?? '0') ??
                          0,
                  lon:
                      double.tryParse(notification['Lon']?.toString() ?? '0') ??
                          0,
                  type: notification['Type'] ?? '',
                  isSmokingAllowed: notification['IsSmokingAllowed'] ?? '',
                  hasGym: notification['HasGym'] ?? '',
                  hasMassage: notification['HasMassage'] ?? '',
                  hasBarber: notification['HasBarber'] ?? '',
                  hasSwimmingPool: notification['HasSwimmingPool'] ?? '',
                  hasKidsArea: notification['HasKidsArea'] ?? '',
                  hasJacuzziInRoom: notification['HasJacuzziInRoom'] ?? '',
                  valetWithFees: notification['ValetWithFees'] ?? '',
                  hasValet: notification['HasValet'] ?? '',
                  lstMusic: notification['Lstmusic'] ?? '',
                ),
              ),
            );
          }
          // If estate is rejected
          else if (estateStatus == "3") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(context, "This estate has been rejected."),
                ),
              ),
            );
          }
          // If estate is under process
          else {
            // We navigate to EditEstate with the entire notification map
            // so all fields appear in the edit form.
            print("Navigating to EditEstate with the following details:");
            print("Estate Object: $notification");
            print("LstRooms: $LstRooms");
            print("Estate Type: ${notification['Type']}");
            print("Estate ID: ${notification['estateId']}");

            if (notification['Type'] == '1') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEstateHotel(
                    objEstate: notification,
                    LstRooms: LstRooms,
                    estateType: notification['Type'] ?? '12',
                    estateId: notification['estateId'] ?? '',
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEstate(
                    objEstate: notification,
                    LstRooms: LstRooms,
                    estateType: notification['Type'] ?? '1',
                    estateId: notification['estateId'] ?? '',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated(context, 'Provider Notifications'),
          style: const TextStyle(color: kDeepPurpleColor),
        ),
        centerTitle: true,
        iconTheme: kIconTheme,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : estateNotifications.isEmpty
                ? Center(
                    child: Text(
                      getTranslated(context, "You have not added any estates"),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: estateNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(estateNotifications[index]);
                    },
                  ),
      ),
    );
  }
}
