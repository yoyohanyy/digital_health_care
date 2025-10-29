import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../DTO/sleepRecordDTO.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Firestore에서 사용자 문서 가져오기
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(
    String userId,
  ) async {
    return await _db.collection('users').doc(userId).get();
  }

  Future<void> saveTodaySleepData(
    String userId,
    Map<String, dynamic> sleepInfo,
  ) async {
    final today = DateTime.now();
    final dateId =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final docRef = _db
        .collection('sleep_records')
        .doc(userId)
        .collection('daily')
        .doc(dateId);

    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data()!;
      final oldInfo = (data['sleepInfo'] as Map<String, dynamic>?) ?? {};

      await docRef.update({
        'sleepInfo': {
          'startTime': sleepInfo['startTime'] ?? oldInfo['startTime'],
          'endTime': sleepInfo['endTime'] ?? oldInfo['endTime'],
          'totalHours': sleepInfo['totalHours'] ?? oldInfo['totalHours'],
          'deepSleep': sleepInfo['deepSleep'] ?? oldInfo['deepSleep'],
        },
        'satisfaction': sleepInfo['satisfaction'] ?? data['satisfaction'] ?? 0,
        'sendMessage': sleepInfo['sendMessage'] ?? data['sendMessage'] ?? "",
        'feedback': sleepInfo['feedback'] ?? data['feedback'] ?? "",
        'updatedAt': Timestamp.now(),
      });
    } else {
      await docRef.set({
        'sleepInfo': {
          'startTime': sleepInfo['startTime'],
          'endTime': sleepInfo['endTime'],
          'totalHours': sleepInfo['totalHours'],
          'deepSleep': sleepInfo['deepSleep'],
        },
        'satisfaction': sleepInfo['satisfaction'] ?? 0,
        'feedback': sleepInfo['feedback'] ?? '',
        'sendMessage': sleepInfo['sendMessage'] ?? "",
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  Future<List<SleepRecord>> getWeeklySleep(
    String userId, {
    int days = 7,
  }) async {
    DateTime today = DateTime.now();
    DateTime start = today.subtract(Duration(days: days - 1));

    List<SleepRecord> records = [];

    for (int i = 0; i < days; i++) {
      DateTime dateKey = DateTime(start.year, start.month, start.day + i);
      String docId =
          "${dateKey.year}-${dateKey.month.toString().padLeft(2, '0')}-${dateKey.day.toString().padLeft(2, '0')}";

      DocumentSnapshot doc =
          await _db
              .collection('sleep_records')
              .doc(userId)
              .collection('daily')
              .doc(docId)
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final info = (data['sleepInfo'] as Map<String, dynamic>?) ?? {};

        double toDouble(dynamic value) {
          if (value is int) return value.toDouble();
          if (value is double) return value;
          return 0.0;
        }

        records.add(
          SleepRecord(
            date: dateKey,
            startTime: (info['startTime'] as Timestamp?)?.toDate(),
            endTime: (info['endTime'] as Timestamp?)?.toDate(),
            totalHours: toDouble(info['totalHours']),
            deepSleep: toDouble(info['deepSleep']),
            satisfaction: data['satisfaction'] ?? 0,
            feedback: data['feedback'] ?? '',
            createdAt: data['createdAt'] ?? Timestamp.now(),
            updatedAt: data['updatedAt'] ?? Timestamp.now(),
          ),
        );
      } else {
        records.add(SleepRecord.empty(dateKey));
      }
    }

    return records;
  }
}
