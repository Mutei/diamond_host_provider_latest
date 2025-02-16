import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/animations_widgets/build_shimmer_loader.dart';
import 'package:daimond_host_provider/screens/coffee_screen.dart';
import 'package:daimond_host_provider/screens/restaurant_screen.dart';
import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:daimond_host_provider/widgets/estate_card_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../animations_widgets/build_shimmer_estate_card.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../backend/adding_estate_services.dart'; // Import the service
import '../widgets/custom_category_button.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/search_text_form_field.dart';
import 'hotel_screen.dart';
import 'profile_estate_screen.dart';
import 'maps_screen.dart'; // Import MapsScreen

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  _MainScreenContentState createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent>
    with WidgetsBindingObserver {
  final EstateServices estateServices = EstateServices();
  final CustomerRateServices customerRateServices = CustomerRateServices();
  final AddEstateServices backendService =
      AddEstateServices(); // Instantiate the service
  final List<String> categories = ['Hotel', 'Restaurant', 'Cafe'];

  List<Map<String, dynamic>> estates = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool isLoading = true;
  bool permissionsChecked = false;
  bool searchActive = false;
  String typeAccount = '';

  String selectedCategory = "All"; // Default category
  final TextEditingController searchController = TextEditingController();
  String firstName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(_filterEstates); // Add listener for search
    _checkPermissionsAndFetchData();
    _fetchUserFirstName();
    _fetchUserTypeAccount();
    // Fetch user's first name on initialization
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.removeListener(_filterEstates);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndFetchData();
    }
  }

  Future<void> _checkPermissionsAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    permissionsChecked = prefs.getBool('permissionsChecked') ?? false;

    if (!permissionsChecked) {
      await _initializePermissions();
      await prefs.setBool('permissionsChecked', true);
    }

    // Fetch estates immediately and permissions first
    await _fetchEstates();
    await _checkIncompleteEstates(); // Check for incomplete estates
  }

  Future<void> _initializePermissions() async {
    // Check Location Permission
    PermissionStatus locationStatus = await Permission.location.status;
    if (locationStatus.isDenied || locationStatus.isRestricted) {
      locationStatus = await Permission.location.request();
    }

    if (locationStatus.isPermanentlyDenied) {
      _showPermissionDialog(
        getTranslated(context, "Location Permission Required"),
        getTranslated(context,
            "Please enable location permission in settings to use the map features."),
      );
    }

    // Check Notification Permission
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isRestricted) {
      notificationStatus = await Permission.notification.request();
    }

    if (notificationStatus.isPermanentlyDenied) {
      _showPermissionDialog(
        getTranslated(context, "Notification Permission Required"),
        getTranslated(
            context, "Please enable notification permission in settings."),
      );
    }
  }

  void _showPermissionDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserFirstName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userRef = FirebaseDatabase.instance.ref("App/User/$userId");
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          // Cast the value to String and handle null values gracefully
          firstName = snapshot.child('FirstName').value?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _fetchEstates() async {
    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data)
          .where((estate) => estate['IDUser'] == userId)
          .toList();

      // Fetch ratings concurrently
      await Future.wait(parsedEstates.map((estate) async {
        await _fetchRatings(estate);
      }));

      setState(() {
        estates = parsedEstates;
        filteredEstates = estates; // Initialize filteredEstates
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching estates: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRatings(Map<String, dynamic> estate) async {
    final ratings =
        await customerRateServices.fetchEstateRatingWithUsers(estate['id']);
    final totalRating = ratings.isNotEmpty
        ? ratings.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
            ratings.length
        : 0.0;

    estate['rating'] = totalRating;
    estate['ratingsList'] = ratings;
  }

  void _fetchUserTypeAccount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userRef =
          FirebaseDatabase.instance.ref("App/User/$userId/TypeAccount");

      // Listen for real-time updates
      userRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            typeAccount = event.snapshot.value.toString();
          });
        }
      });
    }
  }

  List<Map<String, dynamic>> _parseEstates(Map<String, dynamic> data) {
    final estateList = <Map<String, dynamic>>[];
    data.forEach((type, estatesByType) {
      estatesByType.forEach((estateID, estateData) {
        if (estateData['IsAccepted'] == "2") {
          estateList.add({
            'id': estateID,
            'nameEn': estateData['NameEn'] ?? 'Unknown',
            'typeAccount': estateData['TypeAccount'] ?? 'Unknown',
            'nameAr': estateData['NameAr'] ?? 'غير معروف',
            'rating': 0.0,
            'fee': estateData['Fee'] ?? 'Free',
            'time': estateData['Time'] ?? '20 min',
            'TypeofRestaurant':
                estateData['TypeofRestaurant'] ?? 'Unknown Type',
            'BioEn': estateData['BioEn'] ?? "Unknown Bio",
            'BioAr': estateData['BioAr'] ?? "Unknown Bio",
            'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
            'MenuLink': estateData['MenuLink'] ?? 'No Menu',
            'Entry': estateData['Entry'] ?? 'Empty',
            'Lstmusic': estateData['Lstmusic'] ?? 'No music',
            'Type': estateData['Type'] ?? "No type",
            'IDUser': estateData['IDUser'],
            'IsAccepted': estateData['IsAccepted'] ?? '0',
            'Lat': estateData['Lat'] ?? 0,
            'Lon': estateData['Lon'] ?? 0,
            'HasKidsArea': estateData['HasKidsArea'] ?? 'No Kids Allowed',
            'HasValet': estateData['HasValet'] ?? "No valet",
            'ValetWithFees': estateData['ValetWithFees'] ?? "No fees",
            'HasBarber': estateData['HasBarber'] ?? "No Barber",
            'HasMassage': estateData['HasMassage'] ?? "No massage",
            'HasSwimmingPool':
                estateData['HasSwimmingPool'] ?? "No Swimming Pool",
            'HasGym': estateData['HasGym'] ?? "No Gym",
            'IsSmokingAllowed':
                estateData['IsSmokingAllowed'] ?? "Smoking is not allowed",
            'HasJacuzziInRoom': estateData['HasJacuzziInRoom'] ?? "No Jacuzzi",
            'IsCompleted': estateData['IsCompleted'] ?? "0",
          });
        }
      });
    });
    return estateList;
  }

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;
        filteredEstates = estates.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
      } else {
        searchActive = false;
        filteredEstates = estates;
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      searchActive = false;
      filteredEstates = estates;
    });
  }

  String _getGreeting() {
    final currentHour = DateTime.now().hour;
    if (currentHour < 12) {
      return getTranslated(context, "Good Morning");
    } else if (currentHour < 18) {
      return getTranslated(context, "Good Afternoon");
    } else {
      return getTranslated(context, "Good Evening");
    }
  }

  Future<void> _checkIncompleteEstates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Query estates with 'IsCompleted': '0' and 'IDUser': userId
    final DatabaseReference estatesRef =
        FirebaseDatabase.instance.ref("App").child("Estate");

    // Fetch all estates
    DataSnapshot snapshot = await estatesRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> estatesData =
          snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> incompleteEstates = [];

      estatesData.forEach((type, estatesByType) {
        estatesByType.forEach((estateID, estateData) {
          if (estateData['IDUser'] == userId &&
              estateData['IsCompleted'] == "0") {
            incompleteEstates.add({
              'id': estateID,
              'type': type,
              'nameEn': estateData['NameEn'] ?? 'Unknown',
              'nameAr': estateData['NameAr'] ?? 'غير معروف',
            });
          }
        });
      });

      // Only show the dialog if the MainScreenContent is the current route
      // and there are incomplete estates.
      if (incompleteEstates.isNotEmpty &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIncompleteEstateDialog(incompleteEstates);
        });
      }
    }
  }

  void _showIncompleteEstateDialog(
      List<Map<String, dynamic>> incompleteEstates) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Incomplete Estates")),
          content: Text(getTranslated(context,
              "You have incomplete estates. Do you want to continue adding them?")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to MapsScreen for the first incomplete estate
                final firstEstate = incompleteEstates.first;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MapsScreen(
                      id: firstEstate['id'],
                      typeEstate: firstEstate['type'],
                    ),
                  ),
                );
              },
              child: Text(getTranslated(context, "OK")),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(getTranslated(context, "Cancel")),
            ),
          ],
        );
      },
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == "All") {
        filteredEstates = estates;
      } else {
        filteredEstates = estates
            .where((estate) =>
                estate['Type']?.toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      body: isLoading
          ? const Center(child: ShimmerEstateCard())
          : estates.isEmpty
              ? Center(
                  child: Text(
                    getTranslated(
                        context, "You have not added any estates yet."),
                    style: kSecondaryStyle,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchEstates,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display greeting with the user's first name
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                "${_getGreeting()}, ",
                                // style: kPrimaryStyle.copyWith(fontSize: 22),
                                style: const TextStyle(
                                  color: kEstatesTextsColor,
                                  fontSize: 22,
                                ),
                              ),
                              Text(firstName,
                                  style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        // Search Text Field
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SearchTextField(
                            controller: searchController,
                            onClear: _clearSearch,
                            onChanged: (value) => _filterEstates(),
                          ),
                        ),
                        // 10.kH,
                        // // Category Buttons (Hotel, Cafe, Restaurant)
                        // Padding(
                        //   padding: const EdgeInsets.only(left: 22.0),
                        //   child: SingleChildScrollView(
                        //     scrollDirection: Axis.horizontal,
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                        //       children: [
                        //         CustomCategoryButton(
                        //           label: getTranslated(context, "Hotel"),
                        //           icon: Icons.hotel,
                        //           backgroundColor: Colors.blueAccent,
                        //           onTap: () {
                        //             Navigator.push(
                        //               context,
                        //               MaterialPageRoute(
                        //                   builder: (context) =>
                        //                       const HotelScreen()),
                        //             );
                        //           },
                        //         ),
                        //         CustomCategoryButton(
                        //           label: getTranslated(context, "Coffee"),
                        //           icon: Icons
                        //               .coffee, // You might need to add the font package if not available by default
                        //           backgroundColor: Colors.brown,
                        //           onTap: () {
                        //             Navigator.push(
                        //               context,
                        //               MaterialPageRoute(
                        //                   builder: (context) =>
                        //                       const CoffeeScreen()),
                        //             );
                        //           },
                        //         ),
                        //         CustomCategoryButton(
                        //           label: getTranslated(context, "Restaurant"),
                        //           icon: Icons.restaurant,
                        //           backgroundColor: Colors.deepOrange,
                        //           onTap: () {
                        //             Navigator.push(
                        //               context,
                        //               MaterialPageRoute(
                        //                   builder: (context) =>
                        //                       const RestaurantScreen()),
                        //             );
                        //           },
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        15.kH,
                        // Display filtered or all estates
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            searchActive
                                ? getTranslated(context, "Search Results")
                                : getTranslated(context, "My Estates"),
                            // style: kPrimaryStyle.copyWith(fontSize: 22),
                            style: const TextStyle(
                              color: kEstatesTextsColor,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        filteredEstates.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    getTranslated(context, "No results found"),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: filteredEstates.length,
                                itemBuilder: (context, index) {
                                  final estate = filteredEstates[index];
                                  return GestureDetector(
                                    onTap: () =>
                                        _navigateToEstateProfile(estate),
                                    child: EstateCard(
                                        nameEn: estate['nameEn'],
                                        estateId: estate['id'],
                                        nameAr: estate['nameAr'],
                                        rating: estate['rating'],
                                        typeAccount: typeAccount),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _navigateToEstateProfile(Map<String, dynamic> estate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEstateScreen(
          nameEn: estate['nameEn'],
          nameAr: estate['nameAr'],
          estateId: estate['id'],
          estateType: estate['Type'],
          location: "Rose Garden",
          rating: estate['rating'],
          fee: estate['fee'],
          deliveryTime: estate['time'],
          price: 32.0,
          typeOfRestaurant: estate['TypeofRestaurant'],
          bioEn: estate['BioEn'],
          bioAr: estate['BioAr'],
          sessions: estate['Sessions'],
          menuLink: estate['MenuLink'],
          entry: estate['Entry'],
          music: estate['Lstmusic'],
          lat: estate['Lat'] ?? 0,
          lon: estate['Lon'] ?? 0,
          type: estate['Type'],
          isSmokingAllowed: estate['IsSmokingAllowed'] ?? "",
          hasGym: estate['HasGym'] ?? "",
          hasMassage: estate['HasMassage'] ?? '',
          hasBarber: estate['HasBarber'] ?? '',
          hasSwimmingPool: estate['HasSwimmingPool'] ?? '',
          hasKidsArea: estate['HasKidsArea'] ?? '',
          hasJacuzziInRoom: estate['HasJacuzziInRoom'] ?? '',
          valetWithFees: estate['ValetWithFees'] ?? '',
          hasValet: estate['HasValet'] ?? '',
          lstMusic: estate['Lstmusic'] ?? '',
        ),
      ),
    );
  }
}
