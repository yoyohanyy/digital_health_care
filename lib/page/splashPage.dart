// splashPage.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../DTO/userDTO.dart';
import 'loginPage.dart';
import 'mainPage.dart';
import '../services/healthService.dart';
import '../services/kakaoService.dart';
import '../services/firebaseService.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final HealthService _healthService = HealthService();
  final KakaoService _kakaoService = KakaoService();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    //_kakaoService.logout(); // 디버그용 로그아웃
    // 1️⃣ 카카오 로그인 확인
   bool isLoggedIn = await _kakaoService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    // Health Connect 설치 안내 (필요 시)
    await _healthService.installHealthConnect();
    await _healthService.getSdkStatus();
    // 2️⃣ 권한 확인 및 필요 시 요청
    await _healthService.authorize();


    // SplashPage 끝나면 MainPage로 이동
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A202C),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFAEC6CF),
        ),
      ),
    );
  }
}
