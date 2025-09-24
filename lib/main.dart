import 'package:flutter/material.dart';

import 'package:health_care_app/page/mainPage.dart';
import './services/healthService.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final HealthService _healthService = HealthService();
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState(); // 먼저 호출
    _initHealth();
  }

  /// Health Connect 권한 요청
  Future<void> _initHealth() async {
    // Health Connect 설치 안내 (필요시)
    await _healthService.installHealthConnect();

    // 권한 요청
    await _healthService.authorize();

    // 실제 권한 여부 확인
    bool sdkAvailable = await _healthService.getSdkStatus();
    setState(() {
      _permissionGranted = sdkAvailable;
    });

    debugPrint(
      sdkAvailable
          ? 'Health Connect 권한 및 SDK 사용 가능'
          : 'Health Connect 권한 거부 또는 SDK 미설치',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A202C),
      ),
      home: const MainPage(),
    );
  }
}
