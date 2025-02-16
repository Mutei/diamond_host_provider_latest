import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';
import 'add_estate_screen.dart';

class TypeEstate extends StatefulWidget {
  @override
  String Check;

  TypeEstate({required this.Check});

  _State createState() => new _State(Check);
}

class _State extends State<TypeEstate> {
  String Check;
  _State(this.Check);
  final GlobalKey<ScaffoldState> _scaffoldKey1 = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final objProvider = Provider.of<GeneralProvider>(context, listen: false);

    return Scaffold(
      key: _scaffoldKey1,
      appBar: ReusedAppBar(
        title: getTranslated(context, "Select an Estate"),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: objProvider.TypeService(context).length,
          itemBuilder: (BuildContext context, int index) {
            final customerType = objProvider.TypeService(context)[index];
            return GestureDetector(
              onTap: () {
                if (Check == "Add an Estate") {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddEstatesScreen(
                            userType: customerType.type,
                          )));
                }
              },
              child: Card(
                elevation: 5, // Adds a shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: kDeepPurpleColor
                              .withOpacity(0.2), // Icon background color
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          customerType.icon, // Display the icon
                          size: 40,
                          color: kDeepPurpleColor,
                        ),
                      ),
                      const SizedBox(width: 16), // Space between icon and text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerType.name,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: kDeepPurpleColor, // Title color
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              customerType.subtext,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[600], // Subtitle color
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16.0,
                        color: Colors.grey,
                      ), // Arrow for navigation
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
