import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String formatTimestamp(dynamic value) {
  if (value == null) return '';
  final dt = value is Timestamp
      ? value.toDate()
      : DateTime.tryParse(value.toString());
  if (dt == null) return value.toString();
  return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}'
         ' at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

class ViewSessionsScreen extends StatelessWidget {
  const ViewSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in.')),
      );
    }

    final sessionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('startTime', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Sessions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: sessionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No sessions found.'));
          }

          final sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index].data() as Map<String, dynamic>;
              final id = session['sessionId'] ?? 'unknown';
              final rawStart = session['startTime'];
              final start = formatTimestamp(session['startTime']);
              final points = (session['dataPoints'] as List?)?.length ?? 0;

              return ListTile(
                title: Text('Session $id'),
                subtitle: Text('Started: $start\nPoints: $points'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailsScreen(sessionId: id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SessionDetailsScreen extends StatelessWidget {
  final String sessionId;
  const SessionDetailsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final eventsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('events')
        .orderBy('ts');

    return Scaffold(
      appBar: AppBar(title: Text('Session $sessionId')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('sessions')
            .doc(sessionId)
            .snapshots(),
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No data found for this session.'));
            }
            final sessionData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final dataPoints = (sessionData['dataPoints'] as List?) ?? [];
            if (dataPoints.isEmpty) {
                return const Center(child: Text('No posture points recorded.'));
            }
            double avgScore = 0;
            double avgConf = 0;
            for (var p in dataPoints) {
                avgScore += (p['postureScore'] ?? 0);
                avgConf += (p['confidence'] ?? 0);
            }
            avgScore /= dataPoints.length;
            avgConf /= dataPoints.length;

            return Column(
                children: [
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                            'Average posture: ${avgScore.toStringAsFixed(1)}   '
                            'Average confidence: ${(avgConf * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                    ),
                    Expanded(
                    child: ListView.builder(
                        itemCount: dataPoints.length,
                        itemBuilder: (context, i) {
                            final p = dataPoints[i] as Map<String, dynamic>;
                            final rawTs = p['timestamp'];
                            final ts = formatTimestamp(p['timestamp']);
                            final score =
                                (p['postureScore'] ?? 0).toStringAsFixed(1);
                            final conf = ((p['confidence'] ?? 0) * 100).toStringAsFixed(0);
                            return ListTile(
                                title: Text('Score: $score   Confidence: $conf%'),
                                subtitle: Text('Time: $ts'),
                            );
                        },
                    ),
                    ),
                ],
            );
        },
      ),
    );
  }
}
