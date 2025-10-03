import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../DTO/sleepRecordDTO.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> saveSleepData({
    required String userId,
    required String date,
    required DateTime startTime,
    required DateTime endTime,
    required double totalHours,
    required double deepSleep,
    required int satisfaction,
    required String feedback,
    required createdAt,
    required updatedAt,
  }) async {
    try {
      final sleepRef = _db
          .collection('sleepRecords')
          .doc(userId)
          .collection('daily')
          .doc(date);

      await sleepRef.set({
        'startTime': startTime,
        'endTime': endTime,
        'totalHours': totalHours,
        'deepSleep': deepSleep,
        'satisfaction': satisfaction,
        'feedback': feedback,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      });

      print("✅ 수면 데이터 저장 성공");
    } catch (e) {
      print("❌ 수면 데이터 저장 실패: $e");
    }
  }

  /// 최근 7일 수면 시간 가져오기
  Future<Map<DateTime, double>> getWeeklySleep(String userId) async {
    DateTime now = DateTime.now();
    DateTime weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 6));

    QuerySnapshot snapshot = await _db
        .collection('sleepRecords')
        .doc(userId)
        .collection('daily')
        .where('startTime', isGreaterThanOrEqualTo: weekStart)
        .orderBy('startTime')
        .get();

    Map<DateTime, double> weeklyHours = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime start = (data['startTime'] as Timestamp).toDate();
      DateTime end = (data['endTime'] as Timestamp).toDate();
      double hours = end.difference(start).inMinutes / 60.0;

      // 날짜만 key로 사용
      DateTime dateKey = DateTime(start.year, start.month, start.day);
      weeklyHours[dateKey] = (weeklyHours[dateKey] ?? 0) + hours;
    }

    // 7일치 0으로 채우기
    for (int i = 0; i < 7; i++) {
      DateTime date = weekStart.add(Duration(days: i));
      weeklyHours[date] = weeklyHours[date] ?? 0.0;
    }

    return weeklyHours;
  }


  Future<void> newsaveSleepData(String userId, Map<String, dynamic> sleepInfo) async {
    final record = SleepRecord(
      userId: userId,
      date: DateTime.now(),
      startTime: sleepInfo['startTime'] ?? DateTime.now(),
      endTime: sleepInfo['endTime'] ?? DateTime.now(),
      totalHours: sleepInfo['totalMinutes'] ?? 0,
      deepSleep: sleepInfo['deepSleep'] ?? 0,
      satisfaction: 0, // 초기값
      feedback: '',    // 초기값
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    final docId = "${DateTime.now().toIso8601String()}_$userId";

    await FirebaseFirestore.instance
        .collection('sleep_records')
        .doc(docId)
        .set(record.toMap());

    debugPrint("수면 데이터 저장 완료: $docId");
  }
}
