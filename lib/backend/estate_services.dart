import 'package:firebase_database/firebase_database.dart';

class EstateServices {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref().child('App').child('Estate');

  Future<Map<String, dynamic>> fetchEstates() async {
    final snapshot = await databaseRef.get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      throw Exception("No estate data found");
    }
  }
}
