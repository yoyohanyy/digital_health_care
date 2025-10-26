import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/kakaoService.dart';
import 'loginPage.dart';
import 'package:provider/provider.dart';
import '../provider/userProvider.dart'; // ✅ UserProvider import

class MyPage extends StatelessWidget {
  MyPage({super.key});

  final KakaoService _kakaoService = KakaoService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user; // ✅ 로그인된 사용자 정보

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
            // 🔹 프로필 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // ✅ 프로필 이미지
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    backgroundImage: (user?.profileImage != null &&
                        user!.profileImage.isNotEmpty)
                        ? NetworkImage(user.profileImage)
                        : null,
                    child: (user == null || user.profileImage.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // ✅ 닉네임 및 이메일 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nickname ?? "사용자 이름",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            _menuTile(context, "건강 데이터 연동하기"),
            _menuTile(context, "카카오 챗봇 연결하기",
                onTap: () => _showChatbotModal(context)),
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
  Future<void> _showChatbotModal(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final userId = user?.id;

    if (userId == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userDocRef.get();
    final data = snapshot.data();

    String? authCode = data?['authCode'];
    String? chatbotId = data?['chatbotId'];

    // ✅ 이미 챗봇 연결이 완료된 경우 (authCode == null && chatbotId != null)
    if (chatbotId != null && (authCode == null || authCode.isEmpty)) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2D3748),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "카카오 챗봇 연결 완료",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "이미 카카오 챗봇과 연결되어 있습니다.\n이제 수면 리포트를 챗봇으로 받아볼 수 있습니다 😊",
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return;
    }

    // ✅ 연결이 아직 안된 경우 (authCode 없으면 새로 발급)
    if (authCode == null || authCode.isEmpty) {
      authCode = _generateAuthCode();
      await userDocRef.update({'authCode': authCode});
    }

    // ✅ 인증코드 안내 모달
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF2D3748),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "카카오 챗봇 연결하기",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "아래 인증 코드를 카카오톡 챗봇 대화창에 입력하면 연결이 완료됩니다.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authCode!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "연결 방법:",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "1️⃣ 카카오톡에서 ‘수면 매니저 챗봇’을 추가합니다.\n"
                    "2️⃣ 챗봇 대화창에 위 인증코드를 입력합니다.\n"
                    "3️⃣ 연결이 완료되면 수면 피드백을 받을 수 있습니다.",
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
  /// ✅ 인증 코드 생성 (6자리, 숫자+영문)
  String _generateAuthCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
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
