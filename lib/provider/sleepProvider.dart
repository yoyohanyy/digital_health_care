import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../DTO/sleepRecordDTO.dart';

class SleepRecordProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SleepRecord> _records = [];
  List<SleepRecord> get records => _records;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // userId로 최근 days일간 수면 기록 불러오기
  Future<void> fetchRecords(String userId, {int days = 7}) async {
    _isLoading = true;
    notifyListeners();

    DateTime today = DateTime.now();
    DateTime start = today.subtract(Duration(days: days - 1));

    List<SleepRecord> loadedRecords = [];
    for (int i = 0; i < days; i++) {
      DateTime dateKey = DateTime(start.year, start.month, start.day + i);
      String docId =
          "${dateKey.year}-${dateKey.month.toString().padLeft(2, '0')}-${dateKey.day.toString().padLeft(2, '0')}";
      DocumentSnapshot doc =
          await _firestore
              .collection('sleep_records')
              .doc(userId)
              .collection('daily')
              .doc(docId)
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final sleepInfo = data['sleepInfo'] ?? {};
        loadedRecords.add(
          SleepRecord(
            date: dateKey,
            startTime:
                (sleepInfo['startTime'] as Timestamp?)?.toDate() ?? dateKey,
            endTime: (sleepInfo['endTime'] as Timestamp?)?.toDate() ?? dateKey,
            totalHours: (sleepInfo['totalHours'] ?? 0).toDouble(),
            deepSleep: (sleepInfo['deepSleep'] ?? 0).toDouble(),
            satisfaction: (data['satisfaction'] ?? 0).toInt(),
            feedback: data['feedback'] ?? '',
            createdAt: data['createdAt'] ?? Timestamp.now(),
            updatedAt: data['updatedAt'] ?? Timestamp.now(),
          ),
        );
      } else {
        loadedRecords.add(
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

    loadedRecords.sort((a, b) => b.date.compareTo(a.date));
    _records = loadedRecords;
    _isLoading = false;
    notifyListeners();
  }

  // 새로운 수면 기록 추가 또는 업데이트
  Future<void> saveRecord(String userId, SleepRecord record) async {
    String docId =
        "${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}";

    await _firestore
        .collection('sleep_records')
        .doc(userId)
        .collection('daily')
        .doc(docId)
        .set({
          'sleepInfo': {
            'startTime': record.startTime,
            'endTime': record.endTime,
            'totalHours': record.totalHours,
            'deepSleep': record.deepSleep,
          },
          'satisfaction': record.satisfaction,
          'feedback': record.feedback,
          'createdAt': record.createdAt,
          'updatedAt': record.updatedAt,
        }, SetOptions(merge: true));

    // provider 내부 목록 업데이트
    int index = _records.indexWhere(
      (r) =>
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day,
    );
    if (index >= 0) {
      _records[index] = record;
    } else {
      _records.insert(0, record);
    }

    notifyListeners();
  }

  void setRecords(List<SleepRecord> newRecords) {
    _records = newRecords;
    _records.sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    notifyListeners();
  }
}
