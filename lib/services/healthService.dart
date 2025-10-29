import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();

  HealthService() {
    _health.configure();
  }

  /// Android only: Health Connect 설치 안내
  Future<void> installHealthConnect() async {
    if (!Platform.isAndroid) return;
    try {
      await _health.installHealthConnect();
      debugPrint("Health Connect 설치 안내 완료");
    } catch (e) {
      debugPrint("Health Connect 설치 실패: $e");
    }
  }

  /// Android only: SDK 상태 확인
  Future<bool> getSdkStatus() async {
    if (!Platform.isAndroid) return false;
    try {
      debugPrint('SDK 상태 확인 중...');
      final status = await _health.getHealthConnectSdkStatus();
      debugPrint('SDK 상태: $status');
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('SDK 상태 확인 실패: $e');
      return false;
    }
  }

  /// 수면 데이터 타입 정의 (Android/iOS)
  List<HealthDataType> get types =>
      Platform.isAndroid
          ? [
            HealthDataType.SLEEP_SESSION,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_AWAKE,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_LIGHT,
            HealthDataType.SLEEP_REM,
          ]
          : [
            HealthDataType.SLEEP_IN_BED,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_AWAKE,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_LIGHT,
            HealthDataType.SLEEP_REM,
          ];

  /// READ + WRITE 권한
  List<HealthDataAccess> get permissions =>
      List.generate(types.length, (_) => HealthDataAccess.READ_WRITE);

  /// 권한 확인 및 요청 (Android + iOS)
  Future<void> authorize() async {
    try {
      bool? hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );

      if (hasPermissions != true) {
        bool authorized = await _health.requestAuthorization(
          types,
          permissions: permissions,
        );

        if (authorized) {
          debugPrint("Health 권한 허용됨");
        } else {
          debugPrint("Health 권한 거부됨");
        }
      } else {
        debugPrint("이미 Health 권한 있음");
      }
    } catch (error) {
      debugPrint("권한 요청 중 오류: $error");
    }
  }

  /// 수면 데이터 가져오기 (기본: 어제~오늘)
  Future<List<HealthDataPoint>> getSleepData({
    DateTime? start,
    DateTime? end,
  }) async {
    start ??= DateTime.now().subtract(const Duration(days: 1));
    end ??= DateTime.now();
    try {
      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
    } catch (e) {
      debugPrint('수면 데이터 가져오기 실패: $e');
      return [];
    }
  }

  /// 하루 전체 수면 시간 계산
  Future<Map<String, dynamic>> fetchDailySleepData() async {
    await authorize();

    List<HealthDataPoint> sleepData = await getSleepData();

    if (sleepData.isEmpty) {
      return {
        'sleepString': "데이터 없음",
        'totalMinutes': 0,
        'totalHours': 0.0,
        'startTime': null,
        'endTime': null,
        'deepSleep': 0.0,
      };
    }

    int totalMinutes = 0;
    DateTime? firstStart;
    DateTime? lastEnd;
    double deepSleep = 0;

    for (var point in sleepData) {
      if (point.type == HealthDataType.SLEEP_SESSION) {
        final start = point.dateFrom.toLocal();
        final end = point.dateTo.toLocal();
        totalMinutes += end.difference(start).inMinutes;

        if (firstStart == null || start.isBefore(firstStart))
          firstStart = start;
        if (lastEnd == null || end.isAfter(lastEnd)) lastEnd = end;
      }

      if (point.type == HealthDataType.SLEEP_DEEP) {
        deepSleep +=
            (point.value is num ? (point.value as num).toDouble() : 0.0);
      }
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String sleepString =
        totalMinutes == 0
            ? "데이터 없음"
            : (minutes == 0 ? "$hours시간" : "$hours시간 $minutes분");

    return {
      'sleepString': sleepString,
      'totalMinutes': totalMinutes,
      'totalHours': totalMinutes / 60.0,
      'startTime': firstStart,
      'endTime': lastEnd,
      'deepSleep': deepSleep,
    };
  }

  /// 특정 날짜의 수면 데이터 가져오기
  Future<Map<String, dynamic>> fetchDailySleepDataForDate(DateTime date) async {
    await authorize();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sleepData = await getSleepData(start: startOfDay, end: endOfDay);

    if (sleepData.isEmpty) {
      return {
        'date': date,
        'sleepString': "데이터 없음",
        'totalMinutes': 0,
        'totalHours': 0.0,
        'startTime': null,
        'endTime': null,
        'deepSleep': 0.0,
      };
    }

    int totalMinutes = 0;
    DateTime? firstStart;
    DateTime? lastEnd;
    double deepSleep = 0;

    for (var point in sleepData) {
      if (point.type == HealthDataType.SLEEP_SESSION) {
        final start = point.dateFrom.toLocal();
        final end = point.dateTo.toLocal();
        totalMinutes += end.difference(start).inMinutes;

        if (firstStart == null || start.isBefore(firstStart))
          firstStart = start;
        if (lastEnd == null || end.isAfter(lastEnd)) lastEnd = end;
      }

      if (point.type == HealthDataType.SLEEP_DEEP) {
        deepSleep +=
            (point.value is num ? (point.value as num).toDouble() : 0.0);
      }
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String sleepString =
        totalMinutes == 0
            ? "데이터 없음"
            : (minutes == 0 ? "$hours시간" : "$hours시간 $minutes분");

    return {
      'date': date,
      'sleepString': sleepString,
      'totalMinutes': totalMinutes,
      'totalHours': totalMinutes / 60.0,
      'startTime': firstStart,
      'endTime': lastEnd,
      'deepSleep': deepSleep,
    };
  }
}
