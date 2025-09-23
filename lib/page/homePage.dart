import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 9, minutes: 20, seconds: 11);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("홈"),
        backgroundColor: const Color(0xFF1A202C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("안녕하세요 동은님!", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            _infoCard([
              const Text("오늘 동은님의 추천 취침 시간은", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              const Text(
                "오후 12시 00분",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text("수면 시작 까지"),
              const SizedBox(height: 10),
              Text(
                _formatDuration(_timeLeft),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text("설정 기상 시간 : 오전 8시 00분"),
              const SizedBox(height: 5),
              TextButton(onPressed: () {}, child: const Text("수정하기")),
            ]),

            const SizedBox(height: 20),

            _infoCard([
              const Text("동은님의 오늘 총 수면 시간은"),
              const SizedBox(height: 10),
              const Text(
                "총 5시간 53분",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text("어제보다 1시간 3분 적어요!"),
            ]),

            const SizedBox(height: 20),

            _infoCard([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("어제의 내가 오늘의 나에게"),
                  Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }
}

