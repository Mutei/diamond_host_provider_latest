import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserInfoService {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref().child('App').child('User');

  Future<Map<String, String?>> fetchUserInfo() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseEvent event = await databaseRef.child(id).once();
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'FirstName': data['FirstName'],
          'SecondName': data['SecondName'],
          'LastName': data['LastName'],
          'Email': data['Email'],
          'PhoneNumber': data['PhoneNumber'],
          'Country': data['Country'],
          'City': data['City'],
          'ProfileImageUrl': data['ProfileImageUrl'],
          'userId': data['userId']
        };
      }
    }
    return {};
  }

  Future<bool> updateTypeUserAccount(String newAccountType) async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      try {
        await databaseRef.child(id).update({
          'TypeAccount': newAccountType,
        });
        return true;
      } catch (e) {
        print("Error updating TypeAccount: $e");
        return false;
      }
    }
    return false;
  }

  Future<Map<String, String?>> fetchTypeUserAccount() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseEvent event = await databaseRef.child(id).once();
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'TypeAccount': data['TypeAccount'],
        };
      }
    }
    return {};
  }

  Future<Map<String, String?>> firstName() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseEvent event = await databaseRef.child(id).once();
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'FirstName': data['FirstName'],
        };
      }
    }
    return {};
  }

  Future<Map<String, String?>> secondName() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseEvent event = await databaseRef.child(id).once();
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'SecondName': data['SecondName'],
        };
      }
    }
    return {};
  }

  Future<Map<String, String?>> lastName() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseEvent event = await databaseRef.child(id).once();
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'LastName': data['LastName'],
        };
      }
    }
    return {};
  }
}
