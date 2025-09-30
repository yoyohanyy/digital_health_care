import 'package:flutter/material.dart';

class LetterPage extends StatefulWidget {
  const LetterPage({super.key});

  @override
  State<LetterPage> createState() => _LetterPageState();
}

class _LetterPageState extends State<LetterPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // HomePage와 동일한 배경색 및 테마 적용
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        title: const Text(
          "내일의 나에게",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
        // 뒤로가기 아이콘 색상 변경
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              // TODO: 채팅 아이콘 클릭 시 동작
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "to 내일의 나에게",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Expanded를 사용하여 TextField가 남은 공간을 모두 차지하도록 함
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null, // 여러 줄 입력 가능
                expands: true, // 부모 위젯의 공간을 모두 차지
                textAlignVertical: TextAlignVertical.top, // 커서를 위에서부터 시작
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "내용을 입력하세요...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2D3748),
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "from 오늘의 내가",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 저장하기 버튼 클릭 시 동작
                  Navigator.pop(context); // 현재 페이지 닫고 이전 화면으로 돌아가기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3748),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "저장하기",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
