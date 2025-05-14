import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

class ListAdd extends StatelessWidget {
  final String id;

  ListAdd(this.id);

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
