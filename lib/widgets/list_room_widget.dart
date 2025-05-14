import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';

class ListRoom extends StatelessWidget {
  final String id;

  ListRoom(this.id);

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      defaultChild: const Center(child: CircularProgressIndicator()),
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
