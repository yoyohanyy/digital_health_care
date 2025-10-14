import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/kakaoService.dart';
import 'loginPage.dart';

class MyPage extends StatelessWidget {
  MyPage({super.key});

  final KakaoService _kakaoService = KakaoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        title: const Text("마이 페이지"),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "이동은",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "wp4106@naver.com",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _menuTile(context, "건강 데이터 연동하기"),
            _menuTile(context, "카카오 챗봇 연결하기"),
            _menuTile(context, "알림 설정?"),
            _menuTile(context, "앱 정보"),
            _menuTile(context, "약관 및 정책"),
            _menuTile(context, "로그아웃", onTap: () => _logout(context)),
            _menuTile(context, "탈퇴하기", isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String text, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap:
            onTap ??
            () {
              // Default TODO action
            },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _kakaoService.logout(); // Log out from Kakao
      if (!context.mounted) return;
      // Navigate back to LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      // Handle errors (optional)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("로그아웃 실패: $e")));
    }
  }
}
