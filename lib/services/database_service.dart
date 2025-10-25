import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/posture_session_data.dart';
import '../data/models/posture_result.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<String> startNewSession() async {
    if (userId == null) {
      throw Exception('Authentication failed');
    }

    final doc =  _db
      .collection('users')
      .doc(userId)
      .collection('sessions')
      .doc();

    await doc.set({
      'sessionId': doc.id,
      'startTime': DateTime.now().toIso8601String(),
    });

    print('created new session, recorded in Firebase database');
    return doc.id;
  }

  Future<void> addPostureDataPoint(String sessionId, PostureResult result) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final dataPoint = PostureSessionDataPoint(
      timestamp: DateTime.now(),
      postureScore: result.postureScore,
      confidence: result.confidence,
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .update({
      'dataPoints': FieldValue.arrayUnion([dataPoint.toJson()])
    });

    print('added data point to session in Firebase database');
  }
}