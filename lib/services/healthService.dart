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
      final status = await _health.getHealthConnectSdkStatus();
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
}
