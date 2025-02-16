// lib/backend/chat_service.dart

import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> sendMessage(
      String estateId, Map<String, dynamic> message) async {
    await _database.child('App/EstateChats/$estateId').push().set(message);
  }

  Future<void> addReaction(
      String estateId, String messageId, String userId, String reaction) async {
    await _database
        .child('App/EstateChats/$estateId/$messageId/reactions/$userId')
        .set(reaction);
  }

  Future<void> removeReaction(
      String estateId, String messageId, String userId) async {
    await _database
        .child('App/EstateChats/$estateId/$messageId/reactions/$userId')
        .remove();
  }

  Stream<DatabaseEvent> getMessagesStream(String estateId) {
    return _database
        .child('App/EstateChats/$estateId')
        .orderByChild('timestamp')
        .onValue;
  }

  // Optional: Fetch a specific message by ID (useful for replies)
  Future<DatabaseEvent> getMessageById(
      String estateId, String messageId) async {
    return await _database.child('App/EstateChats/$estateId/$messageId').once();
  }

// Private chat methods can be added similarly or handled in a separate service
}
