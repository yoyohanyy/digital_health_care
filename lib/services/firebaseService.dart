import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../DTO/sleepRecordDTO.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Firestore에서 사용자 문서 가져오기
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(
    String userId,
  ) async {
    return await _db.collection('users').doc(userId).get();
  }

  /// 오늘 수면 데이터 저장 또는 업데이트
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
      final existingData = docSnap.data()!;
      await docRef.update({
        'startTime': sleepInfo['startTime'] ?? existingData['startTime'],
        'endTime': sleepInfo['endTime'] ?? existingData['endTime'],
        'totalHours': sleepInfo['totalHours'] ?? existingData['totalHours'],
        'deepSleep': sleepInfo['deepSleep'] ?? existingData['deepSleep'],
        'updatedAt': Timestamp.now(),
      });
      debugPrint("⚠️ 오늘 수면 데이터 업데이트 완료: $dateId");
    } else {
      final record = SleepRecord(
        date: today,
        startTime: sleepInfo['startTime'] ?? today,
        endTime: sleepInfo['endTime'] ?? today,
        totalHours: sleepInfo['totalHours'] ?? 0,
        deepSleep: sleepInfo['deepSleep'] ?? 0,
        satisfaction: 0,
        feedback: '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await docRef.set(record.toMap());
      debugPrint("✅ 오늘 수면 데이터 저장 완료: $dateId");
    }
  }

  /// 최근 7일 수면 기록 조회
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
        records.add(SleepRecord.fromMap(doc.data() as Map<String, dynamic>));
      } else {
        records.add(
          SleepRecord(
            date: dateKey,
            startTime: dateKey,
            endTime: dateKey,
            totalHours: 0,
            deepSleep: 0,
            satisfaction: 0,
            feedback: '',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
        );
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }
}
