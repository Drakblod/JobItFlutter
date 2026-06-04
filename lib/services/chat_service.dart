import 'package:firebase_database/firebase_database.dart';
import '../models/job_message.dart';
import 'firebase_parser.dart';

class ChatService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> sendMessage(JobMessage message) async {
    await _db
        .ref('jobs/${message.jobId}/messages')
        .push()
        .set(message.toJson());
  }

  Stream<List<JobMessage>> streamMessages(String jobId) {
    return _db.ref('jobs/$jobId/messages').onValue.map((event) {
      final List<JobMessage> list = [];
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = FirebaseParser.convertToMap(snapshot.value);
        data.forEach((key, val) {
          if (val is Map) {
            list.add(JobMessage.fromJson(val, key));
          }
        });
      }
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  Future<List<JobMessage>> getMessages(String jobId) async {
    final snapshot = await _db.ref('jobs/$jobId/messages').get();
    final List<JobMessage> list = [];
    if (snapshot.exists) {
      final data = FirebaseParser.convertToMap(snapshot.value);
      data.forEach((key, val) {
        if (val is Map) {
          list.add(JobMessage.fromJson(val, key));
        }
      });
    }
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}

