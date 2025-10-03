import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final String userId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int totalHours;         // 분 단위
  final int deepSleep;           // 분 단위
  final int satisfaction;     // 하루 1번 수정 가능
  final String feedback;      // 하루 1번 수정 불가
  final Timestamp createdAt;
  final Timestamp updatedAt;

  SleepRecord({
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.deepSleep,
    required this.satisfaction,
    required this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: (map['sleepInfo']['startTime'] as Timestamp).toDate(),
      endTime: (map['sleepInfo']['endTime'] as Timestamp).toDate(),
      totalHours: map['sleepInfo']['duration'] ?? 0,
      deepSleep: map['deepSleep'] ?? 0,
      satisfaction: map['satisfaction'] ?? 0,
      feedback: map['feedback'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'sleepInfo': {
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'totalHours': totalHours,
        'deepSleep': deepSleep,
      },
      'satisfaction': satisfaction,
      'feedback': feedback,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
