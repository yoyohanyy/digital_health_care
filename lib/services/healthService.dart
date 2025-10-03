import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();

  HealthService() {
    _health.configure();
  }

  /// Health Connect 설치 안내
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
      debugPrint("Health Connect 설치 안내 완료");
    } catch (e) {
      debugPrint("Health Connect 설치 실패: $e");
    }
  }

  /// iOS/Android 수면 데이터 타입 정의
  List<HealthDataType> get types => Platform.isAndroid
      ? [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ]
      : [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  /// READ + WRITE 권한 설정
  List<HealthDataAccess> get permissions =>
      List.generate(types.length, (_) => HealthDataAccess.READ_WRITE);

  /// 권한 확인 및 요청
  Future<void> authorize() async {
    bool? hasPermissions =
    await _health.hasPermissions(types, permissions: permissions);

    if (hasPermissions != true) {
      try {
        bool authorized = await _health.requestAuthorization(
          types,
          permissions: permissions,
        );
        if (authorized) {
          debugPrint("수면 데이터 READ/WRITE 권한 허용됨");
        } else {
          debugPrint("수면 데이터 권한 거부됨");
        }
      } catch (error) {
        debugPrint("권한 요청 중 오류: $error");
      }
    } else {
      debugPrint("이미 수면 데이터 권한 있음");
    }
  }

  /// Health Connect SDK 상태 확인
  Future<bool> getSdkStatus() async {
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

  /// 수면 데이터 가져오기 (default: 어제~오늘)
  Future<List<HealthDataPoint>> getSleepData(
      {DateTime? start, DateTime? end}) async {
    start ??= DateTime.now().subtract(const Duration(days: 1));
    end ??= DateTime.now();
    try {
      final sleepData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
      return sleepData;
    } catch (e) {
      debugPrint('수면 데이터 가져오기 실패: $e');
      return [];
    }
  }

  /// 하루 전체 수면 시간 문자열과 총 수면 정보를 반환
  Future<Map<String, dynamic>> fetchDailySleepData() async {
    await authorize(); // 권한 요청

    List<HealthDataPoint> sleepData = await getSleepData();

    if (sleepData.isEmpty) {
      // 수면 데이터 없을 경우 기본값 반환
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
        final duration = end.difference(start).inMinutes;
        totalMinutes += duration;

        if (firstStart == null || start.isBefore(firstStart)) firstStart = start;
        if (lastEnd == null || end.isAfter(lastEnd)) lastEnd = end;
      }

      if (point.type == HealthDataType.SLEEP_DEEP) {
        deepSleep += (point.value is num ? (point.value as num).toDouble() : 0.0);
      }
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    String sleepString = totalMinutes == 0 ? "데이터 없음" : (minutes == 0 ? "$hours시간" : "$hours시간 $minutes분");

    return {
      'sleepString': sleepString,
      'totalMinutes': totalMinutes,
      'totalHours': totalMinutes / 60.0,
      'startTime': firstStart,
      'endTime': lastEnd,
      'deepSleep': deepSleep,
    };
  }
}