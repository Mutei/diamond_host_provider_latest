import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePictureService {
  Future<String> uploadImageToStorage(Uint8List image, String userId) async {
    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');
      UploadTask uploadTask = storageRef.putData(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e.toString());
      return '';
    }
  }

  Future<void> saveImageUrlToDatabase(String userId, String imageUrl) async {
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('App')
        .child('User')
        .child(userId);
    await userRef.update({'ProfileImageUrl': imageUrl});
  }

  Future<void> updateProfilePictureInPosts(
      String userId, String newProfileImageUrl) async {
    try {
      DatabaseReference postsRef =
          FirebaseDatabase.instance.ref("App").child("AllPosts");
      DatabaseEvent event = await postsRef.once();
      Map<dynamic, dynamic>? postsData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (postsData != null) {
        for (var key in postsData.keys) {
          if (postsData[key]['userId'] == userId) {
            await postsRef.child(key).update({
              'ProfileImageUrl': newProfileImageUrl,
            });
          }
        }
        print('Profile picture updated in all posts');
      }
    } catch (e) {
      print('Error updating profile picture in posts: $e');
    }
  }
}
