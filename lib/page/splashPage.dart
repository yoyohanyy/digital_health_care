import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import '../DTO/userDTO.dart' as udto;
import '../provider/userProvider.dart';
import '../provider/sleepProvider.dart';
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
    try {
      // 1️⃣ 로그인 확인
      bool isLoggedIn = await _kakaoService.isLoggedIn();
      if (!isLoggedIn) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      // 2️⃣ 카카오 사용자 정보 가져오기
      User kakaoUser = await UserApi.instance.me();
      String userId = kakaoUser.id.toString();

      // 3️⃣ Health 권한 및 데이터 요청
      if (Platform.isAndroid) {
        await _healthService.installHealthConnect();
        await _healthService.getSdkStatus();
        await _healthService.authorize();
      } else if (Platform.isIOS) {
        await _healthService.authorize();
      }

      // 4️⃣ Firestore에서 사용자 정보 가져오기
      final userDoc = await _firebaseService.getUserDoc(userId);

      if (!userDoc.exists || userDoc.data() == null) {
        // 새 사용자면 Firestore에 생성
        await _kakaoService.saveUserInfo();
      }

      final data = userDoc.data() ?? {};

      // 5️⃣ Provider에 사용자 정보 저장
      Provider.of<UserProvider>(context, listen: false).setUser(
        udto.User(
          id: userId,
          authCode: '',
          chatbotId: data['chatbotId'] ?? '',
          nickname: data['nickname'] ?? '',
          profileImage: data['profileImage'] ?? '',
          sleepStartTime: data['sleepStartTime'] ?? '22:00',
          recommendedWakeUpTime: data['recommendedWakeUpTime'] ?? '06:00',
        ),
      );

      // 6️⃣ 수면 데이터 가져오기
      Map<String, dynamic> sleepInfo =
          await _healthService.fetchDailySleepData();

      if (sleepInfo['totalMinutes'] != null && sleepInfo['totalMinutes'] > 0) {
        await _firebaseService.saveTodaySleepData(userId, sleepInfo);
      } else {
        debugPrint("⚠️ 오늘 수면 데이터 없음");
      }

      // 7️⃣ 최근 7일 수면 데이터 가져오기
      final sleepRecords = await _firebaseService.getWeeklySleep(
        userId,
        days: 7,
      );
      Provider.of<SleepRecordProvider>(
        context,
        listen: false,
      ).setRecords(sleepRecords);

      // 8️⃣ 메인 페이지로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } catch (e, stack) {
      debugPrint("❌ SplashPage 초기화 오류: $e");
      debugPrint(stack.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A202C),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFAEC6CF))),
    );
  }
}
