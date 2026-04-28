import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get _chatRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('chats');
  }

  static Future<void> save(String role, String message) async {
    await _chatRef.add({
      'role': role,
      'message': message,
      'time': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> stream() {
    return _chatRef.orderBy('time').snapshots();
  }
}
