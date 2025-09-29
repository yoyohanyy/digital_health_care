import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  Future<void> saveSleepData({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalHours,
    required double deepSleep,
    required int sleepEfficiency,
  }) async {
    try {
      final sleepRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleepRecords');

      await sleepRef.add({
        'deepSleep': deepSleep,
        'startTime': startTime,
        'endTime': endTime,
        'totalHours': totalHours,
        'sleepEfficiency': sleepEfficiency,
        'savedAt': FieldValue.serverTimestamp(),
      });

      print("✅ 수면 데이터 저장 성공");
    } catch (e) {
      print("❌ 수면 데이터 저장 실패: $e");
    }
  }

  Future<Map<DateTime, double>> getWeeklySleepFromFirestore(String userId) async {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: 6));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sleepRecords')
        .where('startTime', isGreaterThanOrEqualTo: weekStart)
        .orderBy('startTime')
        .get();

    Map<DateTime, double> weeklyHours = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime start = (data['startTime'] as Timestamp).toDate();
      DateTime end = (data['endTime'] as Timestamp).toDate();
      double hours = end.difference(start).inMinutes / 60.0;

      // 날짜만 key로 사용 (시간 제거)
      DateTime dateKey = DateTime(start.year, start.month, start.day);
      weeklyHours[dateKey] = (weeklyHours[dateKey] ?? 0) + hours;
    }

    // 7일치 채우기
    for (int i = 0; i < 7; i++) {
      DateTime date = weekStart.add(Duration(days: i));
      weeklyHours[date] = weeklyHours[date] ?? 0.0;
    }

    return weeklyHours;
  }
}
