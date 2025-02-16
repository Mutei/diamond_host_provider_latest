import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';
import 'package:intl/src/intl/date_format.dart';
import '../localization/language_constants.dart';
import '../utils/additional_facility.dart';
import '../utils/rooms.dart';
import 'main_screen.dart';


class DateBooking extends StatefulWidget {
  final Map Estate;
  final List<Rooms> LstRooms;
  final List<Additional> LstAdditional;

  DateBooking({
    required this.Estate,
    required this.LstRooms,
    required this.LstAdditional,
  });

  @override
  State<DateBooking> createState() =>
      _DateBookingState(Estate, LstAdditional, LstRooms);
}

class _DateBookingState extends State<DateBooking> {
  DateTimeRange? _selectedDateRange;
  final Map Estate;
  final List<Rooms> LstRooms;
  final List<Additional> LstAdditional;

  _DateBookingState(this.Estate, this.LstAdditional, this.LstRooms);

  String? FromDate = "x ";
  String? EndDate = "x ";
  int? countofday = 0;
  double netTotal = 0;

  DatabaseReference bookingRef =
  FirebaseDatabase.instance.ref("App").child("Booking");
  DatabaseReference refRooms =
  FirebaseDatabase.instance.ref("App").child("Booking").child("Room");
  DatabaseReference refAdd =
  FirebaseDatabase.instance.ref("App").child("Booking").child("Additional");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterLayoutWidgetBuild());
  }

  void afterLayoutWidgetBuild() async {
    _show();
  }

  void _show() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate:
      DateTime(now.year, now.month, now.day), // Restrict to today or later
      lastDate: DateTime(2030, 12, 31),
      currentDate: now,
      saveText: 'Done',
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
        FromDate = _selectedDateRange!.start.toString();
        EndDate = _selectedDateRange!.end.toString();
        countofday = _selectedDateRange!.end
            .difference(_selectedDateRange!.start)
            .inDays;
      });
      // Recalculate the total after the date is set
      CalcuTotal();
    }
  }

  String generateUniqueOrderID() {
    var random = Random();
    return (random.nextInt(90000) + 10000)
        .toString(); // Generates a 5-digit number
  }

  Future<String> getUserFullName() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    DatabaseReference userRef =
    FirebaseDatabase.instance.ref("App/User/$userId");
    DataSnapshot snapshot = await userRef.get();
    if (snapshot.exists) {
      String firstName = snapshot.child("FirstName").value.toString();
      String secondName = snapshot.child("SecondName").value.toString();
      String lastName = snapshot.child("LastName").value.toString();
      return "$firstName $secondName $lastName";
    }
    return "";
  }

  // Fetch the AverageRating from the TotalProviderFeedbackToCustomer node
  Future<double?> fetchAverageUserRating(String userId) async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");

    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.parse(snapshot.value.toString());
    }
    return null; // Return null if no ratings found
  }

  Future<void> _createBooking() async {
    String uniqueID = generateUniqueOrderID();
    String IDBook = uniqueID;
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Fetch user information
    DatabaseReference userRef =
    FirebaseDatabase.instance.ref("App").child("User").child(userId!);
    DataSnapshot snapshot = await userRef.get();
    String firstName = snapshot.child("FirstName").value?.toString() ?? "";
    String secondName = snapshot.child("SecondName").value?.toString() ?? "";
    String lastName = snapshot.child("LastName").value?.toString() ?? "";
    String smokerStatus = snapshot.child("IsSmoker").value?.toString() ?? "No";
    String allergies = snapshot.child("Allergies").value?.toString() ?? "";
    String fullName = "$firstName $secondName $lastName";
    String? id = FirebaseAuth.instance.currentUser?.uid;
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Fetch the user's average rating from TotalProviderFeedbackToCustomer
    double? userRating = await fetchAverageUserRating(id!);

    // Create booking
    await bookingRef.child("Book").child(IDBook.toString()).set({
      "IDEstate": Estate['IDEstate'].toString(),
      "IDBook": IDBook,
      "NameEn": Estate['NameEn'],
      "NameAr": Estate['NameAr'],
      "Status": "1", // Initial status: "1" for "Under Processing"
      "IDUser": userId,
      "IDOwner": Estate['IDUser'],
      "StartDate": _selectedDateRange?.start.toString(),
      "EndDate": _selectedDateRange?.end.toString(),
      "Type": Estate['Type'],
      "Country": Estate["Country"],
      "State": Estate["State"],
      "City": Estate["City"],
      "NameUser": fullName,
      "Smoker": smokerStatus,
      "Allergies": allergies,
      "NetTotal": netTotal.toString(),
      "read": "0",
      "Rating": userRating ?? 0.0, // Use fetched rating here
      "readuser": "0",
      "DateOfBooking": registrationDate,
    });

    for (var room in LstRooms) {
      await refRooms.child(IDBook).child(room.name).set({
        "ID": room.id,
        "Name": room.name,
        "Price": room.price,
        "BioAr": room.bio,
        "BioEn": room.bioEn,
      });
    }

    for (var additional in LstAdditional) {
      await refAdd.child(IDBook).child(additional.id).set({
        "IDEstate": Estate['IDEstate'].toString(),
        "IDBook": IDBook,
        "NameEn": additional.nameEn,
        "NameAr": additional.name,
        "Price": additional.price,
      });
    }

    // Fetch the provider's FCM token
    String providerId = Estate['IDUser'];
    DatabaseReference providerTokenRef =
    FirebaseDatabase.instance.ref("App/User/$providerId/Token");
    DataSnapshot tokenSnapshot = await providerTokenRef.get();
    String? providerToken = tokenSnapshot.value?.toString();

    // Send notification to the provider
    if (providerToken != null && providerToken.isNotEmpty) {
      await _sendNotificationToProvider(
        providerToken,
        getTranslated(context, "New Booking Request"),
        getTranslated(context, "You have a new booking request"),
      );
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
            getTranslated(context, "Successfully"),
            style: const TextStyle(
              color: kPrimaryColor,
            ),
          )),
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MainScreen()));
  }

  Future<void> _sendNotificationToProvider(
      String token, String title, String body) async {
    // Implement the method to send notification using Firebase Cloud Messaging or any other service
    // This could use a dedicated Firebase function or a third-party service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: ListTile(
                leading: Image(
                    image: AssetImage(Estate['Type'] == "1"
                        ? "assets/images/hotel.png"
                        : Estate['Type'] == "2"
                        ? "assets/images/coffee.png"
                        : "assets/images/restaurant.png")),
                title: Text(
                  Estate["NameEn"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  Estate["Country"] + " \ " + Estate["State"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: ListTile(
                      title: Text("From Date"),
                      subtitle: Text(FromDate!.split(" ")[0]),
                    )),
                Expanded(
                    child: ListTile(
                      title: Text("To Date"),
                      subtitle: Text(EndDate!.split(" ")[0]),
                    ))
              ],
            ),
            Text(
              "Count of Days: " + countofday.toString(),
            ),
            Text(
              getTranslated(context, "Rooms"),
              style: TextStyle(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: ListView.builder(
                  itemCount: LstRooms.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      child: ListTile(
                        title: Text(LstRooms[index].name),
                        trailing: Text(LstRooms[index].price),
                      ),
                    );
                  }),
              height: LstRooms.length * 70,
            ),
            Text(
              getTranslated(context, "additional services"),
              style: TextStyle(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: ListView.builder(
                  itemCount: LstAdditional.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      child: ListTile(
                        title: Text(LstAdditional[index].name),
                        trailing: Text(LstAdditional[index].price),
                      ),
                    );
                  }),
              height: LstAdditional.length * 70,
            ),
            FutureBuilder<String>(
              future: CalcuTotal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else {
                  return Text('No data available');
                }
              },
            ),
            Container(
              height: 20,
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        child: Container(
                          width: 150.w,
                          height: 6.h,
                          margin: const EdgeInsets.only(
                              right: 20, left: 20, bottom: 20),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              getTranslated(context, "Confirm Your Booking"),
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          await _createBooking(); // Use the enhanced booking method
                        },
                      ),
                      flex: 3,
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Future<String> CalcuTotal() async {
    double TotalDayofRoom = 0;
    double TotalDayofAdditional = 0;

    for (int i = 0; i < LstRooms.length; i++) {
      TotalDayofRoom += (double.parse(LstRooms[i].price) *
          double.parse(countofday.toString()));
    }
    for (int i = 0; i < LstAdditional.length; i++) {
      TotalDayofAdditional += (double.parse(LstAdditional[i].price));
    }
    netTotal = TotalDayofRoom + TotalDayofAdditional;

    return TotalDayofRoom.toString() +
        "\n" +
        TotalDayofAdditional.toString() +
        "\n" +
        netTotal.toString();
  }
}