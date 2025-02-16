import 'package:firebase_database/firebase_database.dart';

class CustomerRateServices {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref().child('App').child('CustomerFeedback');

  // Fetch estate rating along with the user who rated
  Future<List<Map<String, dynamic>>> fetchEstateRatingWithUsers(
      String estateId) async {
    List<Map<String, dynamic>> feedbackList = [];

    final snapshot = await databaseRef.get();
    if (snapshot.exists) {
      final feedbacks = snapshot.value as Map<dynamic, dynamic>;

      feedbacks.forEach((key, feedback) {
        if (feedback['EstateID'] == estateId) {
          feedbackList.add({
            'userName': feedback['userName'],
            'rating': (feedback['rating'] as num).toDouble(),
          });
        }
      });
    }

    return feedbackList; // Return the list of ratings and usernames
  }
}
