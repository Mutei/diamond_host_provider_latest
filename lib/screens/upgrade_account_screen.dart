// import 'package:daimond_host_provider/constants/colors.dart';
// import 'package:daimond_host_provider/localization/language_constants.dart';
// import 'package:daimond_host_provider/widgets/reused_appbar.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:daimond_host_provider/constants/styles.dart';
// import 'package:daimond_host_provider/extension/sized_box_extension.dart';
// import '../utils/failure_dialogue.dart';
// import '../utils/success_dialogue.dart';
// import '../widgets/type_account_widget.dart'; // Import the new widget
//
// class UpgradeAccountScreen extends StatefulWidget {
//   const UpgradeAccountScreen({super.key});
//
//   @override
//   _UpgradeAccountScreenState createState() => _UpgradeAccountScreenState();
// }
//
// class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
//   String selectedTypeAccount = '1'; // Default to Star account
//   bool isLoading = false;
//   List<Map<String, String>> accountTypes = [
//     {
//       'type': '1',
//       'title': 'Star',
//       'subtitle':
//           'Book a Cafe, Restaurant, or Hotel where you can join a group chat to provide your full opinion about the service.'
//     },
//     {
//       'type': '2',
//       'title': 'Premium',
//       'subtitle':
//           'Book a Cafe, Restaurant or Hotel where you can join a group chat to provide your full opinion about the service. Add 4 Posts in a month and chat privately with the users.'
//     },
//     {
//       'type': '3',
//       'title': 'Premium Plus',
//       'subtitle':
//           'Book a Cafe, Restaurant or Hotel where you can join a group chat to provide your full opinion about the service. Add 8 Posts in a month and chat privately with the users.'
//     },
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentAccountType();
//   }
//
//   Future<void> _fetchCurrentAccountType() async {
//     setState(() {
//       isLoading = true;
//     });
//     // Fetch the current TypeAccount from the Realtime Database
//     String? id = FirebaseAuth.instance.currentUser?.uid;
//     if (id != null) {
//       DatabaseReference ref =
//           FirebaseDatabase.instance.ref().child('App').child('User').child(id);
//       DatabaseEvent event = await ref.once();
//       if (event.snapshot.exists) {
//         final data = event.snapshot.value as Map<dynamic, dynamic>;
//         setState(() {
//           selectedTypeAccount = data['TypeAccount'] ?? '1';
//           _sortAccountTypes(); // Sort account types based on the current selection
//         });
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   void _sortAccountTypes() {
//     // Sort the accountTypes list to move the user's current account type to the first position
//     accountTypes.sort((a, b) {
//       if (a['type'] == selectedTypeAccount) {
//         return -1;
//       } else if (b['type'] == selectedTypeAccount) {
//         return 1;
//       } else {
//         return 0;
//       }
//     });
//   }
//
//   Future<void> _updateAccountType(String newType) async {
//     setState(() {
//       isLoading = true;
//     });
//     String? id = FirebaseAuth.instance.currentUser?.uid;
//     if (id != null) {
//       try {
//         await FirebaseDatabase.instance
//             .ref()
//             .child('App')
//             .child('User')
//             .child(id)
//             .update({'TypeAccount': newType});
//         setState(() {
//           selectedTypeAccount = newType;
//           _sortAccountTypes(); // Immediately sort after updating account type
//           isLoading = false;
//         });
//         // Show success dialog
//         _showSuccessDialog();
//       } catch (e) {
//         setState(() {
//           isLoading = false;
//         });
//         // Show failure dialog
//         _showFailureDialog();
//       }
//     }
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return const SuccessDialog(
//           text: 'Account Upgrade',
//           text1: 'Your account has been successfully upgraded!',
//         );
//       },
//     );
//   }
//
//   void _showFailureDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return const FailureDialog(
//           text: 'Upgrade Failed',
//           text1: 'There was an error upgrading your account.',
//         );
//       },
//     );
//   }
//
//   // Global method for showing upgrade confirmation dialog
//   void _showUpgradeConfirmationDialog(BuildContext context, String newType) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             "Confirm Upgrade",
//             style: kTeritary,
//           ),
//           content: Text(getTranslated(
//               context, "Are you sure you want to upgrade your account?")),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text(
//                 getTranslated(context, "No"),
//                 style:
//                     const TextStyle(color: kErrorColor), // Customize as needed
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog first
//                 _updateAccountType(newType); // Trigger account update
//               },
//               child: Text(
//                 getTranslated(context, "Yes"),
//                 style: const TextStyle(
//                     color: kConfirmColor), // Customize as needed
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: ReusedAppBar(
//         title: getTranslated(context, "Upgrade account"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text(
//                       getTranslated(context, 'Select your account type:'),
//                       style: kSecondaryStyle.copyWith(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.purple[600], // Refine the color
//                       ),
//                     ),
//                     20.kH,
//                     // Horizontal Scrollable List of Account Types with Centered Content
//                     Center(
//                       child: SizedBox(
//                         height: 550, // Set height of the scrollable cards
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: accountTypes.length,
//                           itemBuilder: (context, index) {
//                             final accountType = accountTypes[index];
//                             return Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 10),
//                               child: Align(
//                                 alignment: Alignment.center,
//                                 child: TypeAccountWidget(
//                                   accountType: accountType['type']!,
//                                   selectedTypeAccount: selectedTypeAccount,
//                                   title: accountType['title']!,
//                                   subtitle: accountType['subtitle']!,
//                                   onSelected: (String accountType) {
//                                     _showUpgradeConfirmationDialog(context,
//                                         accountType); // Show confirmation dialog
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../utils/failure_dialogue.dart';
import '../utils/success_dialogue.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/type_account_widget.dart'; // Import the new widget

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  _UpgradeAccountScreenState createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  String selectedTypeAccount = '1'; // Default to Star account
  bool isLoading = false;
  List<Map<String, String>> accountTypes = [
    {
      'type': '1',
      'titleKey': 'StarTitle', // Add a key for translation
      'subtitleKey': 'StarSubtitle', // Add a key for translation
    },
    {
      'type': '2',
      'titleKey': 'PremiumTitle',
      'subtitleKey': 'PremiumSubtitle',
    },
    {
      'type': '3',
      'titleKey': 'PremiumPlusTitle',
      'subtitleKey': 'PremiumPlusSubtitle',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentAccountType();
  }

  Future<void> _fetchCurrentAccountType() async {
    setState(() {
      isLoading = true;
    });
    // Fetch the current TypeAccount from the Realtime Database
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      DatabaseEvent event = await ref.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          selectedTypeAccount = data['TypeAccount'] ?? '1';
          _sortAccountTypes(); // Sort account types based on the current selection
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _sortAccountTypes() {
    // Sort the accountTypes list to move the user's current account type to the first position
    accountTypes.sort((a, b) {
      if (a['type'] == selectedTypeAccount) {
        return -1;
      } else if (b['type'] == selectedTypeAccount) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  // Future<void> _updateAccountType(String newType) async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   String? id = FirebaseAuth.instance.currentUser?.uid;
  //   if (id != null) {
  //     try {
  //       await FirebaseDatabase.instance
  //           .ref()
  //           .child('App')
  //           .child('User')
  //           .child(id)
  //           .update({'TypeAccount': newType});
  //       setState(() {
  //         selectedTypeAccount = newType;
  //         _sortAccountTypes(); // Immediately sort after updating account type
  //         isLoading = false;
  //       });
  //       // Show success dialog
  //       _showSuccessDialog();
  //     } catch (e) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       // Show failure dialog
  //       _showFailureDialog();
  //     }
  //   }
  // }
  Future<void> _updateAccountType(String newType) async {
    final provider = Provider.of<GeneralProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    try {
      await provider.startSubscription(newType, const Duration(days: 30));
      setState(() {
        isLoading = false;
        _sortAccountTypes();
      });
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SuccessDialog(
          text: 'Account Upgrade',
          text1: 'Your account has been successfully upgraded!',
        );
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const FailureDialog(
          text: 'Upgrade Failed',
          text1: 'There was an error upgrading your account.',
        );
      },
    );
  }

  // Global method for showing upgrade confirmation dialog
  void _showUpgradeConfirmationDialog(BuildContext context, String newType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Upgrade",
            style: kTeritary,
          ),
          content: Text(getTranslated(
              context, "Are you sure you want to upgrade your account?")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                getTranslated(context, "No"),
                style:
                    const TextStyle(color: kErrorColor), // Customize as needed
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                _updateAccountType(newType); // Trigger account update
              },
              child: Text(
                getTranslated(context, "Yes"),
                style: const TextStyle(
                    color: kConfirmColor), // Customize as needed
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Upgrade account"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      getTranslated(context, 'Select your account type:'),
                      style: kSecondaryStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[600], // Refine the color
                      ),
                    ),
                    20.kH,
                    // Horizontal Scrollable List of Account Types with Centered Content
                    Center(
                      child: SizedBox(
                        height: 550, // Set height of the scrollable cards
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: accountTypes.length,
                          itemBuilder: (context, index) {
                            final accountType = accountTypes[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Align(
                                alignment: Alignment.center,
                                child: TypeAccountWidget(
                                  accountType: accountType['type']!,
                                  selectedTypeAccount: selectedTypeAccount,
                                  title: getTranslated(
                                      context, accountType['titleKey']!),
                                  subtitle: getTranslated(
                                      context, accountType['subtitleKey']!),
                                  onSelected: (String accountType) {
                                    _showUpgradeConfirmationDialog(context,
                                        accountType); // Show confirmation dialog
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
