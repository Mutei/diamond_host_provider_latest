import 'dart:async';

import 'package:daimond_host_provider/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _scoped = [];

  String? userId;
  bool isLoading = true;
  List<Rooms> LstRooms = [];

  // ------ Scope persisted by MainScreenContent ------
  static const _kScopeUidKey = 'scope.uid';
  static const _kScopeIsAllKey = 'scope.isAll';
  static const _kScopeEstateIdKey = 'scope.estateId';
  static const _kScopeEstateNameKey = 'scope.estateName';

  bool _scopeAll = true; // default to ALL if nothing saved
  String? _scopeEstateId; // when not ALL
  String? _scopeEstateName; // display only

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    // Background listener (kept as-is)
    _firebaseServices.setupEstateStatusListener();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => isLoading = true);

    await _restoreScopeFromPrefs(); // <-- read what user chose on Main Screen
    await _loadNotifications(); // fetch all estates owned by this user
    _applyScopeFilter(); // filter according to saved scope

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _restoreScopeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final savedUid = prefs.getString(_kScopeUidKey);
    if (savedUid != uid) {
      // different user -> ignore, stick to defaults
      _scopeAll = true;
      _scopeEstateId = null;
      _scopeEstateName = getTranslated(context, "-- All estates --");
      return;
    }

    _scopeAll = prefs.getBool(_kScopeIsAllKey) ?? true;
    if (_scopeAll) {
      _scopeEstateId = null;
      _scopeEstateName = prefs.getString(_kScopeEstateNameKey) ??
          getTranslated(context, "-- All estates --");
    } else {
      _scopeEstateId = prefs.getString(_kScopeEstateIdKey);
      _scopeEstateName =
          prefs.getString(_kScopeEstateNameKey) ?? _scopeEstateId ?? "";
    }
  }

  /// Fetch notifications for a given estate type, storing all data.
  Future<List<Map<String, dynamic>>> _fetchNotificationsForType(
      String estateType) async {
    final notifications = <Map<String, dynamic>>[];
    final ref = FirebaseDatabase.instance.ref("App/Estate").child(estateType);

    try {
      final snapshot = await ref.get();
      if (snapshot.exists) {
        for (final child in snapshot.children) {
          final estateData = Map<String, dynamic>.from(child.value as Map);

          // Filter by owner
          if (estateData['IDUser'] != userId) continue;

          // Extract status
          final estateStatus = estateData['IsAccepted']?.toString() ?? '1';

          // Include all fields + id + status
          notifications.add({
            ...estateData,
            'estateId': child.key,
            'status': estateStatus,
          });
        }
      }
    } catch (e) {
      // ignore or log
      // print("Error fetching notifications for $estateType: $e");
    }
    return notifications;
  }

  /// Load all notifications concurrently for estate types.
  Future<void> _loadNotifications() async {
    _allNotifications.clear();
    final estateTypes = ["Coffee", "Hottel", "Restaurant"];
    final futures = estateTypes.map(_fetchNotificationsForType).toList();

    try {
      final results = await Future.wait(futures);
      final flat = <Map<String, dynamic>>[];
      for (final list in results) {
        flat.addAll(list);
      }

      // de-duplicate by estateId
      final unique = <String, Map<String, dynamic>>{};
      for (final m in flat) {
        unique[m['estateId']] = m;
      }
      _allNotifications = unique.values.toList();
    } catch (_) {
      _allNotifications = [];
    }
  }

  void _applyScopeFilter() {
    if (_scopeAll || _scopeEstateId == null) {
      _scoped = _allNotifications;
    } else {
      _scoped = _allNotifications
          .where((e) => (e['estateId']?.toString() ?? '') == _scopeEstateId)
          .toList();
    }
  }

  /// Builds a card for each estate and handles navigation.
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // localized name
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final estateName =
        isAr ? (notification["NameAr"] ?? '') : (notification["NameEn"] ?? '');

    final estateStatus = notification["status"]?.toString() ?? '1';

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
          if (estateStatus == "2") {
            // Accepted -> Profile
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
                  price: 0.0,
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
          } else if (estateStatus == "3") {
            // Rejected
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(context, "This estate has been rejected."),
                ),
              ),
            );
          } else {
            // Under process -> go to edit (Type '1' means Hotel in your app)
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

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final scopeLabel = _scopeAll
        ? getTranslated(context, "-- All estates --")
        : (_scopeEstateName ?? getTranslated(context, "Choose control scope"));

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
        onRefresh: () async {
          await _restoreScopeFromPrefs(); // reflect any change made on Main Screen
          await _loadNotifications();
          _applyScopeFilter();
          setState(() {});
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allNotifications.isEmpty
                ? Center(
                    child: Text(
                      getTranslated(context, "You have not added any estates"),
                      style: kSecondaryStyle,
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount:
                        _scoped.length + 1, // +1 for the scope chip header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Chip(label: Text(scopeLabel)),
                              // const SizedBox(width: 8),
                              // Text(
                              //   getTranslated(
                              //     context,
                              //     "Change it from Main Screen",
                              //   ),
                              //   style: Theme.of(context)
                              //       .textTheme
                              //       .bodySmall
                              //       ?.copyWith(color: Colors.black54),
                              // ),
                            ],
                          ),
                        );
                      }
                      final item = _scoped[index - 1];
                      return _buildNotificationCard(item);
                    },
                  ),
      ),
    );
  }
}
