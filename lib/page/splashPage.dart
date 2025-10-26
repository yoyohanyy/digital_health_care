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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp(context);
    });
  }

  Future<void> _initApp(BuildContext context) async {
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

   final kakaoUser = await UserApi.instance.me();
   final userId = kakaoUser.id.toString();
    // 3️⃣ 사용자 정보 가져오기
   final userDoc = await FirebaseFirestore.instance
       .collection('users')
       .doc(userId)
       .get();

   final data = userDoc.data()!;

   Provider.of<UserProvider>(context, listen: false).setUser(
     udto.User(
       id: userId,
       authCode: '', // 필요 시 카카오 인증 코드 저장 로직 추가
       chatbotId: data['chatbotId'] ?? '',
       nickname: data['nickname'] ?? '',
       profileImage: data['profileImage'] ?? '',
       sleepStartTime: data['sleepStartTime'] ?? '22:00',
       recommendedWakeUpTime: data['recommendedWakeUpTime'] ?? '06:00',
     ),
   );

    Map<String, dynamic> sleepInfo = await _healthService.fetchDailySleepData();
   if (sleepInfo['totalMinutes'] > 0) {

     // Firebase에 저장
     await _firebaseService.saveTodaySleepData(userId, sleepInfo);
   } else {
     debugPrint("⚠️ 오늘 수면 데이터 없음");
     // 필요시 UI 안내 가능
   }
   final sleepRecords =
   await _firebaseService.getWeeklySleep(userId, days: 7);
   Provider.of<SleepRecordProvider>(context, listen: false).setRecords(sleepRecords);
    // SplashPage 끝나면 MainPage로 이동
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initApp(context),
    builder: (context,snapshot){
      return const Scaffold(
          backgroundColor: Color(0xFF1A202C),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFAEC6CF),
            ),
          ),
        );
      },
    );
  }
}
