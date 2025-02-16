// lib/screens/active_customers_screen.dart

import 'dart:math';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/styles.dart';

/// Function to generate a 5-digit random ID
String generateRandomID() {
  var random = Random();
  int randomID = 10000 + random.nextInt(90000); // Generates a 5-digit number
  return randomID.toString();
}

class ActiveCustomersScreen extends StatefulWidget {
  final String idEstate;
  final String estateName;

  const ActiveCustomersScreen({
    super.key,
    required this.idEstate,
    required this.estateName,
  });

  @override
  ActiveCustomersScreenState createState() => ActiveCustomersScreenState();
}

class ActiveCustomersScreenState extends State<ActiveCustomersScreen> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> activeCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = []; // For the search filter
  Set<String> ratedCustomers = Set<String>();
  String? typeAccount;
  String? providerFullName;
  TextEditingController searchController =
      TextEditingController(); // Search controller

  @override
  void initState() {
    super.initState();
    fetchActiveCustomers();
    fetchTypeAccount();
    initializeRatedCustomers();
    fetchProviderFullName();
  }

  /// Fetch active customers from Firebase
  void fetchActiveCustomers() {
    DatabaseReference activeCustomersRef = databaseReference
        .child('App/EstateChats/${widget.idEstate}/activeUsers');
    activeCustomersRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> activeUsers =
            event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> customers = [];

        // Fetching all customers with full names
        for (var entry in activeUsers.entries) {
          String userId = entry.key;
          String fullName = await getUserFullName(userId);

          // Debugging: Print fetched data
          print('Fetching data for user: $userId');
          print('Data: ${entry.value}');

          customers.add({
            "id": userId,
            "joinedAt": entry.value['joinedAt'], // Corrected Key
            "expiresAt": entry.value['expiresAt'], // Corrected Key
            "FullName": fullName,
          });
        }

        setState(() {
          activeCustomers = customers;
          filteredCustomers = activeCustomers; // Initially show all customers
        });
      } else {
        setState(() {
          activeCustomers = [];
          filteredCustomers = [];
        });
      }
    }, onError: (error) {
      print('Error fetching active customers: $error');
    });
  }

  /// Fetch the type of account for the current user
  Future<void> fetchTypeAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          databaseReference.child("App/User/${user.uid}/TypeAccount");
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          typeAccount = snapshot.value.toString();
        });
        print('TypeAccount: $typeAccount');
      }
    }
  }

  /// Initialize rated customers (if needed)
  Future<void> initializeRatedCustomers() async {
    // Initialize ratedCustomers based on session information
    // Placeholder: Implement if needed
  }

  /// Fetch the full name of the provider
  Future<void> fetchProviderFullName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          databaseReference.child("App/User/${user.uid}");
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        String firstName = snapshot.child("FirstName").value?.toString() ?? "";
        String secondName =
            snapshot.child("SecondName").value?.toString() ?? "";
        String lastName = snapshot.child("LastName").value?.toString() ?? "";
        setState(() {
          providerFullName = "$firstName $secondName $lastName";
        });
        print('Provider Full Name: $providerFullName');
      }
    }
  }

  /// Get the full name of a user by their ID
  Future<String> getUserFullName(String userId) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("App/User").child(userId);
    DataSnapshot snapshot = await userRef.get();
    if (snapshot.exists) {
      String firstName = snapshot.child("FirstName").value?.toString() ?? "";
      String secondName = snapshot.child("SecondName").value?.toString() ?? "";
      String lastName = snapshot.child("LastName").value?.toString() ?? "";
      return "$firstName $secondName $lastName";
    }
    return "Unknown User";
  }

  /// Get the phone number of a user by their ID
  Future<String> getUserPhoneNumber(String userId) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("App/User/$userId/PhoneNumber");
    DataSnapshot snapshot = await userRef.get();

    if (snapshot.exists) {
      return snapshot.value?.toString() ?? "Unknown";
    }
    return "Unknown";
  }

  /// Remove a customer from active users
  Future<void> removeCustomer(String userId) async {
    try {
      await databaseReference
          .child("App/EstateChats/${widget.idEstate}/activeUsers/$userId")
          .remove();
      setState(() {
        activeCustomers.removeWhere((customer) => customer['id'] == userId);
        filteredCustomers.removeWhere((customer) => customer['id'] == userId);
      });

      // Notify chat screen about removal
      DatabaseReference refChat = FirebaseDatabase.instance
          .ref("App/Chat")
          .child(widget.idEstate)
          .child(userId);
      await refChat.remove();

      // **Expire User Access Immediately**
      // Assuming you have a way to notify the customer app, e.g., through a separate node or a messaging service.
      // For simplicity, we'll assume the customer app listens to the activeUsers node.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User removed successfully.')),
      );
    } catch (e) {
      print('Error removing user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove user: $e')),
      );
    }
  }

  /// Rate a customer with a rating and comment
  void rateCustomer(String userId, double rating, String comment) async {
    try {
      // Fetch estate name using the EstateID (widget.idEstate)
      String estateName = await getEstateName(widget.idEstate);

      // Generate a unique 5-digit FeedbackID
      String feedbackID = generateRandomID();

      // Check if this FeedbackID already exists in the database
      DatabaseReference feedbackRef =
          databaseReference.child("App/ProviderFeedbackToCustomer/$feedbackID");
      DataSnapshot feedbackSnapshot = await feedbackRef.get();

      // Ensure uniqueness by regenerating the ID if it already exists
      while (feedbackSnapshot.exists) {
        feedbackID = generateRandomID();
        feedbackRef = databaseReference
            .child("App/ProviderFeedbackToCustomer/$feedbackID");
        feedbackSnapshot = await feedbackRef.get();
      }

      // Fetch customer's full name and phone number
      String customerFullName = await getUserFullName(userId);
      String customerPhone = await getUserPhoneNumber(userId);

      // Use the current EstateID (widget.idEstate) as EstateID
      String estateID = widget.idEstate;

      // Update feedback with FeedbackID as the key
      await databaseReference
          .child("App/ProviderFeedbackToCustomer/$feedbackID")
          .set({
        'CustomerID': userId,
        'CustomerName': customerFullName, // Store customer full name
        'averageRating': rating,
        'ratingCount': 1, // Assume first rating in this case
      });

      // Add the detailed rating and comment under the FeedbackID and CustomerID
      await feedbackRef.child("ratings").child(widget.estateName).set({
        'rating': rating,
        'comment': comment,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'EstateName':
            widget.estateName, // Store the estate name instead of provider name
        'EstateID': estateID, // Store the estate ID
      });

      // Now update the TotalFeedbackToCustomer node
      DatabaseReference totalFeedbackRef = databaseReference
          .child("App/TotalProviderFeedbackToCustomer/$userId");

      DataSnapshot totalFeedbackSnapshot = await totalFeedbackRef.get();

      if (totalFeedbackSnapshot.exists) {
        // Fetch current rating count and total rating from the snapshot safely
        int ratingCount =
            totalFeedbackSnapshot.child("RatingCount").value != null
                ? int.parse(
                    totalFeedbackSnapshot.child("RatingCount").value.toString())
                : 0;

        double totalRating =
            totalFeedbackSnapshot.child("TotalRating").value != null
                ? double.parse(
                    totalFeedbackSnapshot.child("TotalRating").value.toString())
                : 0.0;

        // Update the count and add the new rating to totalRating
        ratingCount += 1;
        totalRating += rating;

        // Calculate the new average rating and format to one decimal place
        double averageRating = totalRating / ratingCount;
        String formattedAverageRating = averageRating.toStringAsFixed(1);

        // Update the existing record in TotalFeedbackToCustomer
        await totalFeedbackRef.update({
          'RatingCount': ratingCount,
          'TotalRating': totalRating,
          'AverageRating': formattedAverageRating, // Save the formatted value
        });
      } else {
        // If this is the first time the customer is being rated
        await totalFeedbackRef.set({
          'UserID': userId,
          'Name': customerFullName,
          'Phone': customerPhone,
          'RatingCount': 1,
          'TotalRating': rating,
          'AverageRating':
              rating.toStringAsFixed(1), // Initial rating as formatted average
        });
      }

      setState(() {
        ratedCustomers.add(userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('User rated $rating stars with comment: "$comment"')),
      );
    } catch (e) {
      print('Error rating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rate user: $e')),
      );
    }
  }

  /// Fetch the estate name based on the EstateID
  Future<String> getEstateName(String estateID) async {
    String estateType =
        getEstateType(estateID); // Get estate type based on ID or widget
    DatabaseReference estateRef =
        databaseReference.child("App/Estate/$estateType/$estateID");
    DataSnapshot snapshot = await estateRef.get();

    if (snapshot.exists) {
      return snapshot.child("NameEn").value?.toString() ?? "Unknown Estate";
    }
    return "Unknown Estate"; // Default if estate name not found
  }

  /// Determine the estate type based on logic or ID
  String getEstateType(String estateID) {
    return "Coffee"; // You can change this to Restaurant, Coffee, or Hotel based on logic
  }

  /// Filter customers based on search query
  void filterCustomers(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCustomers = activeCustomers;
      });
    } else {
      setState(() {
        filteredCustomers = activeCustomers
            .where((customer) => customer['FullName']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

        filteredCustomers.sort((a, b) =>
            a['FullName'].toLowerCase().compareTo(b['FullName'].toLowerCase()));
      });
    }
  }

  /// Format DateTime to a more readable string
  String formatDateTime(DateTime dateTime) {
    // Example format: Jan 28, 2025 4:43 PM
    return "${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated(context, 'Active Customers'),
          style: TextStyle(
            color: kPrimaryColor,
          ),
        ),
        centerTitle: true,
        iconTheme: kIconTheme,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: getTranslated(context, 'Search for customers...'),
                prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: kPrimaryColor),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            filterCustomers(''); // Clear the search query
                          });
                        },
                      )
                    : null, // Show only when there is input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kPrimaryColor),
                ),
              ),
              onChanged: (value) {
                filterCustomers(value); // Filter the list on each keystroke
                setState(() {}); // Update the UI to show/hide clear button
              },
            ),
          ),

          // Active Customers List
          Expanded(
            child: filteredCustomers.isNotEmpty
                ? ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      String userId = filteredCustomers[index]['id'];
                      var expiresAtData = filteredCustomers[index]['expiresAt'];

                      DateTime? expiresAt;

                      // Parse expiresAt based on its data type
                      if (expiresAtData != null) {
                        if (expiresAtData is int) {
                          // If stored as milliseconds since epoch
                          try {
                            expiresAt = DateTime.fromMillisecondsSinceEpoch(
                                expiresAtData);
                          } catch (e) {
                            print(
                                'Error parsing expiresAt for user $userId: $e');
                          }
                        } else if (expiresAtData is String) {
                          // If stored as ISO 8601 string
                          try {
                            expiresAt = DateTime.parse(expiresAtData);
                          } catch (e) {
                            print(
                                'Error parsing expiresAt string for user $userId: $e');
                          }
                        } else {
                          print(
                              'Unexpected expiresAt type for user $userId: ${expiresAtData.runtimeType}');
                        }
                      }

                      String activeUntilText =
                          getTranslated(context, 'Active until: ');
                      if (expiresAt != null) {
                        // Format the DateTime into a readable string
                        activeUntilText += formatDateTime(expiresAt.toLocal());
                      } else {
                        activeUntilText += 'Unknown';
                      }

                      return ListTile(
                        title: Text(
                          filteredCustomers[index]
                              ['FullName'], // Display full name
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          activeUntilText,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          iconColor: kPrimaryColor,
                          onSelected: (value) {
                            if (value == 'rate' &&
                                !ratedCustomers.contains(userId)) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    '${getTranslated(context, "Rate")} ${filteredCustomers[index]['FullName']}',
                                  ),
                                  content: RatingBarDialog(
                                    onSubmit: (rating, comment) {
                                      rateCustomer(userId, rating, comment);
                                    },
                                  ),
                                ),
                              );
                            } else if (value == 'remove') {
                              removeCustomer(userId);
                            }
                          },
                          itemBuilder: (context) => [
                            if (typeAccount == '2' || typeAccount == '3')
                              if (!ratedCustomers.contains(userId))
                                PopupMenuItem(
                                  value: 'rate',
                                  child: Text(
                                    getTranslated(context, 'Rate & Comment'),
                                    style: TextStyle(
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                getTranslated(context, 'Remove'),
                                style: TextStyle(
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      getTranslated(context, 'No active customers found.'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Custom Widget for Rating Dialog
class RatingBarDialog extends StatefulWidget {
  final Function(double, String) onSubmit;

  const RatingBarDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _RatingBarDialogState createState() => _RatingBarDialogState();
}

class _RatingBarDialogState extends State<RatingBarDialog> {
  double _rating = 3.0;
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the constraints of the dialog
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Ensure the dialog doesn't exceed 80% of the screen height
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: getTranslated(context, 'Enter comment'),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    String comment = _commentController.text.trim();
                    if (comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(getTranslated(
                                context, 'Please enter a comment.'))),
                      );
                      return;
                    }
                    widget.onSubmit(_rating, comment);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(getTranslated(context, 'Submit')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
