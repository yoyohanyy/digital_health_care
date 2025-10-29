import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../DTO/userDTO.dart' as udto;
import '../provider/sleepProvider.dart';
import '../provider/userProvider.dart';
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    if (_initialized) return; // 중복 실행 방지
    _initialized = true;
    testFirestore();
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

    await _healthService.installHealthConnect();
    await _healthService.getSdkStatus();
    await _healthService.authorize();

    final kakaoUser = await UserApi.instance.me();
    final userId = kakaoUser.id.toString();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = userDoc.data() ?? {};

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

    // 2️⃣ 오늘 수면 데이터 저장
    Map<String, dynamic>? sleepInfo = await _healthService.fetchDailySleepData();

    if (sleepInfo != null && (sleepInfo['totalMinutes'] ?? 0) > 0) {
      await _firebaseService.saveTodaySleepData(userId, sleepInfo);
    }

    // 3️⃣ 주간 수면 데이터
    final sleepRecords = await _firebaseService.getWeeklySleep(userId, days: 7);

    Provider.of<SleepRecordProvider>(context, listen: false)
        .setRecords(sleepRecords);

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
  Future<void> testFirestore() async {
    try {
      var test = await FirebaseFirestore.instance
          .collection('test')
          .doc('ping')
          .get();
      print("✅ Firestore 연결 성공: ${test.data()}");
    } catch (e) {
      print("❌ Firestore 연결 실패: $e");
    }
  }
}
