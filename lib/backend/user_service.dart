import 'package:firebase_database/firebase_database.dart';

// UserProfile Model
class UserProfile {
  final String firstName;
  final String lastName;
  final String profileImageUrl;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
  });

  // Factory constructor to map Firebase data to UserProfile
  factory UserProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      print('UserProfile.fromMap: map is null');
      return UserProfile(
        firstName: '',
        lastName: '',
        profileImageUrl: '',
      );
    }

    return UserProfile(
      firstName: map['FirstName']?.toString().trim() ?? '',
      lastName: map['LastName']?.toString().trim() ?? '',
      profileImageUrl: map['ProfileImageUrl']?.toString().trim() ?? '',
    );
  }
}

// UserService Class
class UserService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Fetch user profile from Firebase by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('Fetching user profile for userId: $userId');
      DatabaseReference ref = _database.ref('App/User/$userId');
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        print('Snapshot exists for userId: $userId');
        if (snapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          print('Data fetched: $data');
          return UserProfile.fromMap(data);
        } else {
          print('Unexpected data format for userId: $userId');
          print('Snapshot value: ${snapshot.value}');
        }
      } else {
        print('No snapshot found for userId: $userId');
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create or update a user profile in Firebase
  Future<void> createUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? profileImageUrl,
  }) async {
    try {
      await _database.ref('App/User/$userId').set({
        'FirstName': firstName,
        'LastName': lastName,
        'ProfileImageUrl': profileImageUrl ?? '',
      });
      print('User profile created or updated for userId: $userId');
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }
}
