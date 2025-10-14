import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/userProvider.dart';
import 'provider/sleepProvider.dart'; // SleepProvider import
import 'package:firebase_core/firebase_core.dart';
import 'package:health_care_app/page/reportPage.dart';
import './page/splashPage.dart'; // SplashPage import
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '89d79c3a05dd0411019c1f7785ea4939');
  await initializeDateFormatting('ko_KR', null); //한국어 형태의 날짜 받아들이기
  void printKeyHash() async {
    final keyHash = await KakaoSdk.origin;
    print("👉 Current Key Hash: $keyHash");
  }

  printKeyHash();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase 초기화 성공");
  } catch (e) {
    print("❌ Firebase 초기화 실패: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SleepRecordProvider()), // UserProvider 추가
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A202C),
      ),
      home: const SplashPage(),
    );
  }
}
