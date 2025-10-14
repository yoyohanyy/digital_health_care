import 'package:flutter/material.dart';

// 이 페이지에서 쓴 내용을 저장하고 불러오려면 flutter pub add shared_preferences 명령어로 패키지를 추가해야 합니다.
import 'package:shared_preferences/shared_preferences.dart';

class LetterPage extends StatefulWidget {
  const LetterPage({super.key});

  @override
  State<LetterPage> createState() => _LetterPageState();
}

class _LetterPageState extends State<LetterPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLetter(); // 페이지가 시작될 때 저장된 편지 내용을 불러옵니다.
  }

  // 편지 내용을 불러오는 함수
  void _loadLetter() async {
    final prefs = await SharedPreferences.getInstance();
    // 'letter' 키로 저장된 문자열을 불러옵니다. 없으면 빈 문자열을 사용합니다.
    final String savedLetter = prefs.getString('letter') ?? '';
    _controller.text = savedLetter;
  }

  // 편지 내용을 저장하는 함수
  void _saveLetter(String content) async {
    final prefs = await SharedPreferences.getInstance();
    // 'letter'라는 키(key)에 content(편지 내용)를 저장합니다.
    await prefs.setString('letter', content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        title: const Text(
          "내일의 나에게",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions 리스트에서 채팅 아이콘을 제거했습니다.
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
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
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
                  // 1. 컨트롤러에서 현재 입력된 텍스트를 가져옵니다.
                  final String currentText = _controller.text;

                  // 2. 해당 텍스트를 기기에 저장합니다.
                  _saveLetter(currentText);

                  // 3. 현재 페이지를 닫고 이전 화면으로 돌아갑니다.
                  Navigator.pop(context);
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
