import 'package:health/health.dart';

const List<HealthDataType> sleepTypesIOS = [
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_IN_BED,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
];

const List<HealthDataType> sleepTypesAndroid = [
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_AWAKE_IN_BED,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_UNKNOWN,
  HealthDataType.SLEEP_SESSION,
];