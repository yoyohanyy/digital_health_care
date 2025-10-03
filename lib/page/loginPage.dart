import 'package:flutter/material.dart';
import '../services/kakaoService.dart';
import 'splashPage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kakaoService = KakaoService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A202C), // 카카오 색상
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              Icon(
                Icons.bedtime,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 20),

              // 안내 텍스트
              const Text(
                "카카오 계정으로 로그인",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // 카카오 로그인 버튼
              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFAEC6CF), // 텍스트 대비
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.login, color: Colors.yellow[700]),
                  label: const Text(
                    "카카오 로그인",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    bool success = await kakaoService.login();
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SplashPage()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
