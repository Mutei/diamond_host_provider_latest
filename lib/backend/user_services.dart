import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<String> fetchUserName() async {
    User currentUser = _auth.currentUser!;
    DataSnapshot snap =
        await _database.child('App/User/${currentUser.uid}').get();
    Map<dynamic, dynamic> user = snap.value as Map<dynamic, dynamic>;
    return '${user['FirstName']} ${user['SecondName']} ${user['LastName']}';
  }

  Future<String> fetchUserId() async {
    User currentUser = _auth.currentUser!;
    return currentUser.uid;
  }

  Future<String> fetchUserEmail() async {
    User currentUser = _auth.currentUser!;
    DataSnapshot snap =
        await _database.child('App/User/${currentUser.uid}').get();
    Map<dynamic, dynamic> user = snap.value as Map<dynamic, dynamic>;
    return user['Email'];
  }

  User getCurrentUser() {
    return _auth.currentUser!;
  }
}
