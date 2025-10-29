import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final double totalHours;
  final double deepSleep;
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

  factory SleepRecord.empty(DateTime date) => SleepRecord(
    date: date,
    startTime: null,
    endTime: null,
    totalHours: 0,
    deepSleep: 0,
    satisfaction: 0,
    feedback: '',
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  );
}
