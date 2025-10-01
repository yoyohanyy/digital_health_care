import 'package:flutter/material.dart';
import 'homePage.dart';
import 'reportPage.dart';
import 'myPage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 기상/취침 시간 상태 관리
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 0, minute: 0);

  // HomePage에서 호출하여 상태를 변경할 함수
  void _updateSleepTimes(TimeOfDay newWakeUpTime, TimeOfDay newBedTime) {
    setState(() {
      _wakeUpTime = newWakeUpTime;
      _bedTime = newBedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    // build 메서드 안에서 페이지 리스트를 생성하여 상태를 전달
    final List<Widget> pages = [
      HomePage(
        wakeUpTime: _wakeUpTime,
        bedTime: _bedTime,
        onTimesChanged: _updateSleepTimes,
      ),
      ReportPage(wakeUpTime: _wakeUpTime, bedTime: _bedTime),
      const MyPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A202C),
        selectedItemColor: const Color(0xFFAEC6CF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "리포트"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이"),
        ],
      ),
    );
  }
}
