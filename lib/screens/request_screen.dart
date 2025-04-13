// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_database/ui/firebase_animated_list.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:sizer/sizer.dart';
//
// import '../backend/firebase_services.dart';
// import '../constants/colors.dart';
// import '../constants/styles.dart';
//
// import '../localization/language_constants.dart';
//
// import '../state_management/general_provider.dart';
//
// class RequestScreen extends StatefulWidget {
//   @override
//   _RequestScreenState createState() => _RequestScreenState();
// }
//
// class _RequestScreenState extends State<RequestScreen>
//     with SingleTickerProviderStateMixin {
//   final FirebaseServices _firebaseServices =
//       FirebaseServices(); // Instantiate FirebaseServices
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();
//     _tabController = TabController(length: 3, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   // Method to update booking with rating
//   Future<void> updateBookingWithRatingOnSave(
//       String bookingId, String userId) async {
//     // Fetch the user's rating
//     double? userRating = await fetchAverageUserRating(userId);
//
//     // Update the booking with the fetched rating
//     DatabaseReference bookingRef = FirebaseDatabase.instance
//         .ref("App")
//         .child("Booking")
//         .child("Book")
//         .child(bookingId);
//
//     await bookingRef.update({
//       "Rating": userRating ?? 0.0, // Default to 0.0 if no rating exists
//     });
//   }
//
//   // Method to fetch average user rating
//   Future<double?> fetchAverageUserRating(String userId) async {
//     // Fetch the rating from TotalProviderFeedbackToCustomer node
//     DatabaseReference ratingRef = FirebaseDatabase.instance
//         .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");
//
//     DataSnapshot snapshot = await ratingRef.get();
//     if (snapshot.exists) {
//       return double.tryParse(snapshot.value.toString());
//     } else {
//       return null; // Return null if no rating found
//     }
//   }
//
//   // Method to show confirmation dialog
//   Future<void> _showConfirmationDialog(
//       BuildContext context, Map map, String actionType) async {
//     String message = actionType == "accept"
//         ? getTranslated(context, "Are you sure you want to accept the request?")
//         : getTranslated(
//             context, "Are you sure you want to reject the request?");
//     String statusUpdate =
//         actionType == "accept" ? "2" : "3"; // 2 for accept, 3 for reject
//     String actionButtonText = actionType == "accept"
//         ? getTranslated(context, "Confirm")
//         : getTranslated(context, "Reject");
//
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(getTranslated(context, "Confirmation")),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: Text(getTranslated(context, "Cancel")),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(actionButtonText),
//               onPressed: () async {
//                 // Update booking status
//                 DatabaseReference ref = FirebaseDatabase.instance
//                     .ref("App")
//                     .child("Booking")
//                     .child("Book")
//                     .child(map['IDBook']);
//                 await ref.update({"Status": statusUpdate});
//
//                 // Fetch customer FCM token
//                 String customerId = map['IDUser'];
//                 DatabaseReference customerTokenRef =
//                     FirebaseDatabase.instance.ref("App/User/$customerId/Token");
//                 DataSnapshot tokenSnapshot = await customerTokenRef.get();
//                 String? customerToken = tokenSnapshot.value?.toString();
//
//                 // Optionally send notification
//                 // if (customerToken != null && customerToken.isNotEmpty) {
//                 //   await _firebaseServices.sendNotificationToCustomer(
//                 //       customerToken,
//                 //       "Booking Status Update",
//                 //       statusUpdate == "2"
//                 //           ? "Your booking (ID: ${map['IDBook']}) has been accepted."
//                 //           : "Your booking has been rejected.");
//                 // }
//
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // Method to show detailed dialog with rooms and additional services
//   Future<void> _showMyDialog(BuildContext context, Map map) async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Scaffold(
//           appBar: AppBar(
//             iconTheme: kIconTheme,
//             elevation: 0,
//             title: Text(
//               getTranslated(
//                 context,
//                 "Request",
//               ),
//               style: TextStyle(fontSize: 15),
//             ),
//           ),
//           body: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 20),
//                 Container(
//                   width: MediaQuery.of(context).size.width,
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   child: RichText(
//                     text: TextSpan(
//                       text: getTranslated(context, "Booking Details"),
//                       style: TextStyle(
//                           fontSize: 6.w,
//                           fontWeight: FontWeight.bold,
//                           color: kPurpleColor),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Text(
//                   getTranslated(context, "Rooms"),
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 ListRoom(map['IDBook']),
//                 SizedBox(height: 10),
//                 Text(
//                   getTranslated(context, "Additional Services"),
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 ListAdd(map['IDBook']),
//                 SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Confirm'),
//                           style: TextStyle(),
//                         ),
//                         onPressed: () async {
//                           // First close the current dialog
//                           Navigator.of(context).pop();
//
//                           // Show the confirmation dialog
//                           await _showConfirmationDialog(context, map, "accept");
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Reject'),
//                           style: TextStyle(
//                             color: Colors.red,
//                           ),
//                         ),
//                         onPressed: () async {
//                           // First close the current dialog
//                           Navigator.of(context).pop();
//
//                           // Show the confirmation dialog
//                           await _showConfirmationDialog(context, map, "reject");
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Cancel'),
//                           style: TextStyle(),
//                         ),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // Method to show detailed dialog without rooms (Coffe)
//   Future<void> _showMyDialogCoffe(BuildContext context, Map map) async {
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 20),
//                 Container(
//                   width: MediaQuery.of(context).size.width,
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   child: RichText(
//                     text: TextSpan(
//                       text: getTranslated(context, "Booking Details"),
//                       style: TextStyle(
//                           fontSize: 6.w,
//                           fontWeight: FontWeight.bold,
//                           color: kPurpleColor),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Confirm'),
//                           style: TextStyle(),
//                         ),
//                         onPressed: () async {
//                           Navigator.of(context).pop();
//                           await _showConfirmationDialog(context, map, "accept");
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Reject'),
//                           style: TextStyle(
//                             color: Colors.red,
//                           ),
//                         ),
//                         onPressed: () async {
//                           Navigator.of(context).pop();
//                           await _showConfirmationDialog(context, map, "reject");
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: TextButton(
//                         child: Text(
//                           getTranslated(context, 'Cancel'),
//                           style: TextStyle(),
//                         ),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     )
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final objProvider = Provider.of<GeneralProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(getTranslated(context, "Requests")),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: getTranslated(context, "Under Process")),
//             Tab(text: getTranslated(context, "Accepted")),
//             Tab(text: getTranslated(context, "Rejected")),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // Under Process Tab
//           BookingList(
//             status: "1",
//             showDialogFunction: _showMyDialog,
//             showDialogCoffeFunction: _showMyDialogCoffe,
//           ),
//           // Accepted Tab
//           BookingList(
//             status: "2",
//             showDialogFunction: null,
//             showDialogCoffeFunction: null,
//           ),
//           // Rejected Tab
//           BookingList(
//             status: "3",
//             showDialogFunction: null,
//             showDialogCoffeFunction: null,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Widget to display list of bookings based on status
// class BookingList extends StatelessWidget {
//   final String status;
//   final Future<void> Function(BuildContext, Map)? showDialogFunction;
//   final Future<void> Function(BuildContext, Map)? showDialogCoffeFunction;
//
//   BookingList({
//     required this.status,
//     this.showDialogFunction,
//     this.showDialogCoffeFunction,
//   });
//
//   // Method to update booking with rating
//   Future<void> updateBookingWithRatingOnSave(
//       String bookingId, String userId) async {
//     // Fetch the user's rating
//     double? userRating = await fetchAverageUserRating(userId);
//
//     // Update the booking with the fetched rating
//     DatabaseReference bookingRef = FirebaseDatabase.instance
//         .ref("App")
//         .child("Booking")
//         .child("Book")
//         .child(bookingId);
//
//     await bookingRef.update({
//       "Rating": userRating ?? 0.0, // Default to 0.0 if no rating exists
//     });
//   }
//
//   // Method to fetch average user rating
//   Future<double?> fetchAverageUserRating(String userId) async {
//     // Fetch the rating from TotalProviderFeedbackToCustomer node
//     DatabaseReference ratingRef = FirebaseDatabase.instance
//         .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");
//
//     DataSnapshot snapshot = await ratingRef.get();
//     if (snapshot.exists) {
//       return double.tryParse(snapshot.value.toString());
//     } else {
//       return null; // Return null if no rating found
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
//
//     return Container(
//       height: MediaQuery.of(context).size.height,
//       width: MediaQuery.of(context).size.width,
//       child: FirebaseAnimatedList(
//         shrinkWrap: true,
//         defaultChild: const Center(
//           child: CircularProgressIndicator(),
//         ),
//         query: FirebaseDatabase.instance
//             .ref("App")
//             .child("Booking")
//             .child("Book")
//             .orderByChild("Status")
//             .equalTo(status),
//         itemBuilder: (context, snapshot, animation, index) {
//           Map<dynamic, dynamic> value = snapshot.value as Map<dynamic, dynamic>;
//           value['Key'] = snapshot.key;
//           String? id = currentUserId;
//
//           if (value["IDOwner"] == id) {
//             // Update booking with rating
//             return FutureBuilder<void>(
//               future: updateBookingWithRatingOnSave(
//                   value['IDBook'], value['IDUser']),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container(); // or any loading indicator
//                 }
//
//                 String locale = Localizations.localeOf(context).languageCode;
//                 String estateName = locale == 'ar'
//                     ? value["NameAr"] ?? "غير معروف"
//                     : value["NameEn"] ?? "Unknown";
//
//                 return Container(
//                   margin: EdgeInsets.all(10),
//                   width: MediaQuery.of(context).size.width,
//                   child: Card(
//                     color: _getCardColor(value["Status"], context),
//                     child: InkWell(
//                       onTap: () {
//                         if (value["Status"] == "1") {
//                           if (value["EndDate"].toString().isNotEmpty) {
//                             if (showDialogFunction != null &&
//                                 showDialogCoffeFunction != null) {
//                               showDialogFunction!(
//                                   context, value as Map<dynamic, dynamic>);
//                             }
//                           } else {
//                             if (showDialogFunction != null &&
//                                 showDialogCoffeFunction != null) {
//                               showDialogCoffeFunction!(
//                                   context, value as Map<dynamic, dynamic>);
//                             }
//                           }
//                         }
//                       },
//                       child: Wrap(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ItemInCard(
//                                     Icon(Icons.calendar_month),
//                                     value["StartDate"].toString(),
//                                     getTranslated(context, "FromDate")),
//                               ),
//                               Expanded(
//                                 child: value["EndDate"].toString().isNotEmpty
//                                     ? ItemInCard(
//                                         Icon(Icons.calendar_month),
//                                         value["EndDate"].toString(),
//                                         getTranslated(context, "ToDate"))
//                                     : Container(),
//                               )
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ItemInCard(
//                                     Icon(Icons.bookmark_added_sharp),
//                                     value["IDBook"].toString(),
//                                     getTranslated(context, "Booking ID")),
//                               ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ItemInCard(
//                                     Icon(Icons.timer),
//                                     value["Clock"].toString(),
//                                     getTranslated(context, "Time")),
//                               ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ItemInCard(
//                                   Icon(Icons.person),
//                                   value['NameUser'] ?? "",
//                                   getTranslated(context, "Customer Name"),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: value["NetTotal"].toString() != "null"
//                                     ? ItemInCard(
//                                         Icon(Icons.money),
//                                         value["NetTotal"].toString(),
//                                         getTranslated(context, "Total"))
//                                     : Container(),
//                               )
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ListTile(
//                                   leading: Icon(
//                                     Icons.star,
//                                     color: Colors.white,
//                                   ),
//                                   title: Text(
//                                     getTranslated(context, "Rate"),
//                                     style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white),
//                                   ),
//                                   subtitle: Text(
//                                     value['Rating'] != null
//                                         ? double.parse(
//                                                 value['Rating'].toString())
//                                             .toStringAsFixed(1)
//                                         : "0.0",
//                                     style: TextStyle(
//                                         fontSize: 12, color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: ItemInCard(
//                                     Icon(Icons.smoking_rooms),
//                                     value["Smoker"] ?? "No",
//                                     getTranslated(context, "Smoker")),
//                               ),
//                             ],
//                           ),
//                           ItemInCard(
//                               Icon(Icons.notes),
//                               value["Allergies"] ?? "",
//                               getTranslated(context, "Allergies")),
//                           ItemInCard(Icon(Icons.business), estateName,
//                               getTranslated(context, "Estate Name")),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           } else {
//             return Container();
//           }
//         },
//       ),
//     );
//   }
//
//   // Helper method to get card color based on status
//   Color _getCardColor(String? status, BuildContext context) {
//     switch (status) {
//       case "1": // Under Process
//         return Colors.blueGrey[300]!; // Neutral color for under process
//       case "2": // Accepted
//         return Colors.green[800]!; // Teal color for accepted
//       case "3": // Rejected
//         return Colors
//             .red[900]!; // Lighter red for better visibility in dark mode
//       default:
//         return Colors.grey[400]!; // Neutral fallback for unknown statuses
//     }
//   }
// }
//
// // Widget to represent an individual booking item (optional refactoring)
// class BookingItem extends StatelessWidget {
//   final Map map;
//   final Future<void> Function(BuildContext, Map) showMyDialog;
//   final Future<void> Function(BuildContext, Map) showMyDialogCoffe;
//   final Function(String, String, Map) updateBooking;
//
//   BookingItem({
//     required this.map,
//     required this.showMyDialog,
//     required this.showMyDialogCoffe,
//     required this.updateBooking,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: updateBooking(map['IDBook'], map['IDUser'], map),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(); // or any loading indicator
//         }
//
//         String locale = Localizations.localeOf(context).languageCode;
//         String estateName = locale == 'ar'
//             ? map["NameAr"] ?? "غير معروف"
//             : map["NameEn"] ?? "Unknown";
//
//         return Container(
//           margin: EdgeInsets.all(10),
//           width: MediaQuery.of(context).size.width,
//           child: Card(
//             color: _getCardColor(map["Status"], context),
//             child: InkWell(
//               onTap: () {
//                 if (map["Status"] == "1") {
//                   if (map["EndDate"].toString().isNotEmpty) {
//                     showMyDialog(context, map);
//                   } else {
//                     showMyDialogCoffe(context, map);
//                   }
//                 }
//               },
//               child: Wrap(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ItemInCard(
//                           Icon(Icons.calendar_month),
//                           map["StartDate"].toString(),
//                           getTranslated(context, "FromDate"),
//                         ),
//                       ),
//                       Expanded(
//                         child: map["EndDate"].toString().isNotEmpty
//                             ? ItemInCard(
//                                 Icon(Icons.calendar_month),
//                                 map["EndDate"].toString(),
//                                 getTranslated(context, "ToDate"))
//                             : Container(),
//                       )
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ItemInCard(
//                             Icon(Icons.bookmark_added_sharp),
//                             map["IDBook"].toString(),
//                             getTranslated(context, "Booking ID")),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ItemInCard(
//                             Icon(Icons.timer),
//                             map["Clock"].toString(),
//                             getTranslated(context, "Time")),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ItemInCard(
//                           Icon(Icons.person),
//                           map['NameUser'] ?? "",
//                           getTranslated(context, "Customer Name"),
//                         ),
//                       ),
//                       Expanded(
//                         child: map["NetTotal"].toString() != "null"
//                             ? ItemInCard(
//                                 Icon(Icons.money),
//                                 map["NetTotal"].toString(),
//                                 getTranslated(context, "Total"))
//                             : Container(),
//                       )
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ListTile(
//                           leading: Icon(
//                             Icons.star,
//                           ),
//                           title: Text(
//                             getTranslated(context, "Rate"),
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           subtitle: Text(
//                             map['Rating'] != null
//                                 ? double.parse(map['Rating'].toString())
//                                     .toStringAsFixed(1)
//                                 : "0.0",
//                             style: TextStyle(
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: ItemInCard(
//                             Icon(Icons.smoking_rooms),
//                             map["Smoker"] ?? "No",
//                             getTranslated(context, "Smoker")),
//                       ),
//                     ],
//                   ),
//                   ItemInCard(Icon(Icons.notes), map["Allergies"] ?? "",
//                       getTranslated(context, "Allergies")),
//                   ItemInCard(Icon(Icons.business), estateName,
//                       getTranslated(context, "Hottel Name")),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // Helper method to get card color based on status
//   Color _getCardColor(String? status, BuildContext context) {
//     if (status == "1") {
//       return Theme.of(context).brightness == Brightness.dark
//           ? Colors.black
//           : Colors.white;
//     } else if (status == "2") {
//       return Colors.green;
//     } else if (status == "3") {
//       return Colors.red[300]!;
//     } else {
//       return Colors.white;
//     }
//   }
// }
//
// // Widget to display rooms related to a booking
// class ListRoom extends StatelessWidget {
//   final String id;
//
//   ListRoom(this.id);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: FirebaseAnimatedList(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         defaultChild: const Center(
//           child: CircularProgressIndicator(),
//         ),
//         query: FirebaseDatabase.instance
//             .ref("App")
//             .child("Booking")
//             .child("Room")
//             .child(id),
//         itemBuilder: (context, snapshot, animation, index) {
//           Map<dynamic, dynamic>? map;
//           try {
//             map = snapshot.value as Map<dynamic, dynamic>;
//             map['Key'] = snapshot.key;
//           } catch (e) {
//             print(e);
//           }
//           return Container(
//             width: MediaQuery.of(context).size.width,
//             height: 70,
//             child: ListTile(
//               title: Text(getTranslated(context, map?['Name'] ?? "")),
//               leading: Icon(
//                 Icons.single_bed,
//                 color: Color(0xFF84A5FA),
//               ),
//               trailing: Text(
//                 map?['Price'] ?? "",
//                 style: TextStyle(color: Colors.green, fontSize: 18),
//               ),
//               onTap: () async {},
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Widget to display additional services related to a booking
// class ListAdd extends StatelessWidget {
//   final String id;
//
//   ListAdd(this.id);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: FirebaseAnimatedList(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         defaultChild: const Center(
//           child: CircularProgressIndicator(),
//         ),
//         query: FirebaseDatabase.instance
//             .ref("App")
//             .child("Booking")
//             .child("Additional")
//             .child(id),
//         itemBuilder: (context, snapshot, animation, index) {
//           Map<dynamic, dynamic>? map;
//           try {
//             map = snapshot.value as Map<dynamic, dynamic>;
//             map['Key'] = snapshot.key;
//           } catch (e) {
//             print(e);
//           }
//           return Container(
//             width: MediaQuery.of(context).size.width,
//             height: 70,
//             child: ListTile(
//               title: Text(map?['NameEn'] ?? ""),
//               trailing: Text(
//                 map?['Price'] ?? "",
//                 style: TextStyle(color: Colors.green, fontSize: 18),
//               ),
//               onTap: () async {},
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Widget to display individual item in a card
// class ItemInCard extends StatelessWidget {
//   final Icon icon;
//   final String data;
//   final String label;
//   final Widget? additionalWidget;
//
//   ItemInCard(this.icon, this.data, this.label, {this.additionalWidget});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: ListTile(
//         leading: Icon(
//           icon.icon,
//           color: Colors.white,
//         ),
//         title: Text(
//           label,
//           style: TextStyle(
//               fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               data,
//               style: TextStyle(fontSize: 12, color: Colors.white),
//             ),
//             if (additionalWidget != null) additionalWidget!,
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../backend/firebase_services.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    Provider.of<GeneralProvider>(context, listen: false).resetNewRequestCount();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Future<void> updateBookingWithRatingOnSave(
  //     String bookingId, String userId) async {
  //   double? userRating = await fetchAverageUserRating(userId);
  //   await FirebaseDatabase.instance
  //       .ref("App/Booking/Book")
  //       .child(bookingId)
  //       .update({"Rating": userRating ?? 0.0});
  // }

  Future<double?> fetchAverageUserRating(String userId) async {
    DataSnapshot snap = await FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating")
        .get();
    return snap.exists ? double.tryParse(snap.value.toString()) : null;
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, Map map, String actionType) async {
    String message = actionType == "accept"
        ? getTranslated(context, "Are you sure you want to accept the request?")
        : getTranslated(
            context, "Are you sure you want to reject the request?");
    String statusUpdate = actionType == "accept" ? "2" : "3";
    String actionButtonText = actionType == "accept"
        ? getTranslated(context, "Confirm")
        : getTranslated(context, "Reject");

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(getTranslated(context, "Confirmation")),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(getTranslated(context, "Cancel")),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(actionButtonText),
            onPressed: () async {
              await FirebaseDatabase.instance
                  .ref("App/Booking/Book")
                  .child(map['IDBook'])
                  .update({"Status": statusUpdate});
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context, Map map) async {
    final bookingRef =
        FirebaseDatabase.instance.ref("App/Booking/Book").child(map['IDBook']);

    // 1) Fetch CountDays
    final snap = await bookingRef.get();
    final int countDays =
        int.tryParse(snap.child('CountDays').value?.toString() ?? '') ?? 1;

    // 2) Fetch Rooms and sum price * countDays
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

    // 3) Fetch Additional services and sum price
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

    // 4) Compute grand total
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

              // Count of Days
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

              // Computed Total Price
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
                        await _showConfirmationDialog(context, map, "accept");
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
                        await _showConfirmationDialog(context, map, "reject");
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
                        await _showConfirmationDialog(context, map, "accept");
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
                        await _showConfirmationDialog(context, map, "reject");
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: getTranslated(context, "Under Process")),
            Tab(text: getTranslated(context, "Accepted")),
            Tab(text: getTranslated(context, "Rejected")),
          ],
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// (BookingList, ListRoom, ListAdd, ItemInCard remain unchanged)

// ... BookingList, ListRoom, ListAdd, ItemInCard remain unchanged ...

// ─────────────────────────────────────────────────────────────────────────────
// ──────────────────────────── BOOKING LIST WIDGET ───────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class BookingList extends StatelessWidget {
  final String status;
  final Future<void> Function(BuildContext, Map)? showDialogFunction;
  final Future<void> Function(BuildContext, Map)? showDialogCoffeFunction;

  BookingList({
    required this.status,
    this.showDialogFunction,
    this.showDialogCoffeFunction,
  });

  // Method to update booking with rating
  Future<void> updateBookingWithRatingOnSave(
      String bookingId, String userId) async {
    double? userRating = await fetchAverageUserRating(userId);

    DatabaseReference bookingRef = FirebaseDatabase.instance
        .ref("App")
        .child("Booking")
        .child("Book")
        .child(bookingId);

    await bookingRef.update({
      "Rating": userRating ?? 0.0,
    });
  }

  // Method to fetch average user rating
  Future<double?> fetchAverageUserRating(String userId) async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");

    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.tryParse(snapshot.value.toString());
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Provide different messages for different statuses
    String noRequestsText;
    if (status == "1") {
      noRequestsText = getTranslated(context, "No new booking requests");
    } else if (status == "2") {
      noRequestsText = getTranslated(context, "No accepted booking requests");
    } else {
      noRequestsText = getTranslated(context, "No rejected booking requests");
    }

    // Prepare the query
    final DatabaseReference baseRef =
        FirebaseDatabase.instance.ref("App").child("Booking").child("Book");

    final query = baseRef.orderByChild("Status").equalTo(status);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,

      // Use a StreamBuilder to check if data is empty or not
      child: StreamBuilder<DatabaseEvent>(
        stream: query.onValue,
        builder: (context, snapshot) {
          // While loading
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // If there's no data for this status, show a "no requests" text
          if (snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                noRequestsText,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          // Convert the snapshot to a Map to filter out only this owner's bookings
          final dataMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final userBookings = dataMap.entries.where((entry) {
            final bookingData = entry.value as Map<dynamic, dynamic>;
            return bookingData["IDOwner"] == currentUserId;
          }).toList();

          // If none of the bookings belong to the current user, show "no requests"
          if (userBookings.isEmpty) {
            return Center(
              child: Text(
                noRequestsText,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          // If we reach here, there is data for the current user. Build the list.
          return FirebaseAnimatedList(
            query: query,
            shrinkWrap: true,
            defaultChild: const Center(
              child: CircularProgressIndicator(),
            ),
            itemBuilder: (context, animationSnapshot, animation, index) {
              final value =
                  animationSnapshot.value as Map<dynamic, dynamic>? ?? {};
              value['Key'] = animationSnapshot.key;

              // Only show items that belong to the current user
              if (value["IDOwner"] == currentUserId) {
                return FutureBuilder<void>(
                  future: updateBookingWithRatingOnSave(
                      value['IDBook'], value['IDUser']),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container(); // or a loading indicator
                    }

                    // Localized estate name
                    String locale =
                        Localizations.localeOf(context).languageCode;
                    String estateName = locale == 'ar'
                        ? (value["NameAr"] ?? "غير معروف")
                        : (value["NameEn"] ?? "Unknown");

                    // Build your booking card
                    return Container(
                      margin: const EdgeInsets.all(10),
                      child: Card(
                        color: _getCardColor(value["Status"]),
                        child: InkWell(
                          onTap: () {
                            // Only if status = 1 do we show the "accept/reject" dialog
                            if (value["Status"] == "1") {
                              if (value["EndDate"].toString().isNotEmpty) {
                                if (showDialogFunction != null) {
                                  showDialogFunction!(context, value);
                                }
                              } else {
                                if (showDialogCoffeFunction != null) {
                                  showDialogCoffeFunction!(context, value);
                                }
                              }
                            }
                          },
                          child: Wrap(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.calendar_month),
                                      value["StartDate"].toString(),
                                      getTranslated(context, "FromDate"),
                                    ),
                                  ),
                                  Expanded(
                                    child: value["EndDate"]
                                            .toString()
                                            .isNotEmpty
                                        ? ItemInCard(
                                            const Icon(Icons.calendar_month),
                                            value["EndDate"].toString(),
                                            getTranslated(context, "ToDate"),
                                          )
                                        : Container(),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.bookmark_added_sharp),
                                      value["IDBook"].toString(),
                                      getTranslated(context, "Booking ID"),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.timer),
                                      value["Clock"].toString(),
                                      getTranslated(context, "Time"),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.person),
                                      value['NameUser'] ?? "",
                                      getTranslated(context, "Customer Name"),
                                    ),
                                  ),
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.phone_android_outlined),
                                      value['PhoneNumber'] ?? "",
                                      getTranslated(context, "Phone Number"),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      leading: const Icon(Icons.star,
                                          color: Colors.white),
                                      title: Text(
                                        getTranslated(context, "Rate"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        value['Rating'] != null
                                            ? double.parse(
                                                    value['Rating'].toString())
                                                .toStringAsFixed(1)
                                            : "0.0",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ItemInCard(
                                      const Icon(Icons.smoking_rooms),
                                      value["Smoker"] ?? "No",
                                      getTranslated(context, "Smoker"),
                                    ),
                                  ),
                                ],
                              ),
                              ItemInCard(
                                const Icon(Icons.notes),
                                value["Allergies"] ?? "",
                                getTranslated(context, "Allergies"),
                              ),
                              ItemInCard(
                                const Icon(Icons.business),
                                estateName,
                                getTranslated(context, "Estate Name"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Container();
              }
            },
          );
        },
      ),
    );
  }

  // Helper to pick card color based on status
  Color _getCardColor(String? status) {
    switch (status) {
      case "1": // Under Process
        return Colors.blueGrey[300] ?? Colors.grey;
      case "2": // Accepted
        return Colors.green[800] ?? Colors.green;
      case "3": // Rejected
        return Colors.red[900] ?? Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ────────────────────────── OPTIONAL BOOKING ITEM WIDGET ───────────────────
// ─────────────────────────────────────────────────────────────────────────────
// (You may or may not need this, depending on whether you're using it.)
class BookingItem extends StatelessWidget {
  final Map map;
  final Future<void> Function(BuildContext, Map) showMyDialog;
  final Future<void> Function(BuildContext, Map) showMyDialogCoffe;
  final Function(String, String, Map) updateBooking;

  BookingItem({
    required this.map,
    required this.showMyDialog,
    required this.showMyDialogCoffe,
    required this.updateBooking,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: updateBooking(map['IDBook'], map['IDUser'], map),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(); // or any loading indicator
        }

        String locale = Localizations.localeOf(context).languageCode;
        String estateName = locale == 'ar'
            ? map["NameAr"] ?? "غير معروف"
            : map["NameEn"] ?? "Unknown";

        return Container(
          margin: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width,
          child: Card(
            color: _getCardColor(map["Status"], context),
            child: InkWell(
              onTap: () {
                if (map["Status"] == "1") {
                  if (map["EndDate"].toString().isNotEmpty) {
                    showMyDialog(context, map);
                  } else {
                    showMyDialogCoffe(context, map);
                  }
                }
              },
              child: Wrap(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.calendar_month),
                          map["StartDate"].toString(),
                          getTranslated(context, "FromDate"),
                        ),
                      ),
                      Expanded(
                        child: map["EndDate"].toString().isNotEmpty
                            ? ItemInCard(
                                const Icon(Icons.calendar_month),
                                map["EndDate"].toString(),
                                getTranslated(context, "ToDate"),
                              )
                            : Container(),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.bookmark_added_sharp),
                          map["IDBook"].toString(),
                          getTranslated(context, "Booking ID"),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.timer),
                          map["Clock"].toString(),
                          getTranslated(context, "Time"),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.person),
                          map['NameUser'] ?? "",
                          getTranslated(context, "Customer Name"),
                        ),
                      ),
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.phone_android_outlined),
                          map['PhoneNumber'] ?? "",
                          getTranslated(context, "Phone Number"),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.star),
                          title: Text(
                            getTranslated(context, "Rate"),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            map['Rating'] != null
                                ? double.parse(map['Rating'].toString())
                                    .toStringAsFixed(1)
                                : "0.0",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ItemInCard(
                          const Icon(Icons.smoking_rooms),
                          map["Smoker"] ?? "No",
                          getTranslated(context, "Smoker"),
                        ),
                      ),
                    ],
                  ),
                  ItemInCard(
                    const Icon(Icons.notes),
                    map["Allergies"] ?? "",
                    getTranslated(context, "Allergies"),
                  ),
                  ItemInCard(
                    const Icon(Icons.business),
                    estateName,
                    getTranslated(context, "Hottel Name"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCardColor(String? status, BuildContext context) {
    if (status == "1") {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white;
    } else if (status == "2") {
      return Colors.green;
    } else if (status == "3") {
      return Colors.red[300]!;
    } else {
      return Colors.white;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ───────────────────────────── LIST ROOM WIDGET ─────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class ListRoom extends StatelessWidget {
  final String id; // this is the bookingId

  ListRoom(this.id);

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      defaultChild: const Center(child: CircularProgressIndicator()),
      // ← fixed path: now looks under Booking/Book/{bookingId}/Room
      query: FirebaseDatabase.instance
          .ref("App")
          .child("Booking")
          .child("Book")
          .child(id)
          .child("Rooms"),
      itemBuilder: (context, snapshot, animation, index) {
        final map = (snapshot.value as Map<dynamic, dynamic>?) ?? {};
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 70,
          child: ListTile(
            leading: const Icon(Icons.single_bed, color: Color(0xFF84A5FA)),
            title: Text(getTranslated(context, map['Name'] ?? "")),
            trailing: Text(
              map['Price']?.toString() ?? "",
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────── LIST ADDITIONAL WIDGET ─────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class ListAdd extends StatelessWidget {
  final String id; // this is the bookingId

  ListAdd(this.id);

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      defaultChild: const Center(child: CircularProgressIndicator()),
      // ← fixed path: now looks under Booking/Book/{bookingId}/Additional
      query: FirebaseDatabase.instance
          .ref("App")
          .child("Booking")
          .child("Book")
          .child(id)
          .child("Additional"),
      itemBuilder: (context, snapshot, animation, index) {
        final map = (snapshot.value as Map<dynamic, dynamic>?) ?? {};
        final locale = Localizations.localeOf(context).languageCode;
        final name = locale == 'ar' ? map['NameAr'] : map['NameEn'];
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 70,
          child: ListTile(
            title: Text(name ?? ""),
            trailing: Text(
              map['Price']?.toString() ?? "",
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ────────────────────────── ITEM IN CARD WIDGET ─────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class ItemInCard extends StatelessWidget {
  final Icon icon;
  final String data;
  final String label;
  final Widget? additionalWidget;

  ItemInCard(this.icon, this.data, this.label, {this.additionalWidget});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon.icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          if (additionalWidget != null) additionalWidget!,
        ],
      ),
    );
  }
}
