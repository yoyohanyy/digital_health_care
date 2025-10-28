import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double totalHours;
  final int deepSleep;
  final int satisfaction;
  final String feedback;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  SleepRecord({
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
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime:
          (map['sleepInfo']['startTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      endTime:
          (map['sleepInfo']['endTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      totalHours: map['sleepInfo']?['totalHours'] ?? 0,
      deepSleep: map['sleepInfo']?['deepSleep'] ?? 0,
      satisfaction: map['satisfaction'] ?? 0,
      feedback: map['feedback'] ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalHours': totalHours,
      'deepSleep': deepSleep,
      'satisfaction': satisfaction,
      'feedback': feedback,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
