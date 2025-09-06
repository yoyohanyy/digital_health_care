import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
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
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // Start with 리포트 page

  final List<Widget> _pages = const [
    Center(child: Text("홈 페이지", style: TextStyle(color: Colors.white))),
    ReportPage(),
    Center(child: Text("마이 페이지", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A202C),
        selectedItemColor: Color(0xFFAEC6CF),
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

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        title: const Text(
          "리포트",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "일간"), Tab(text: "주간"), Tab(text: "월간")],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(),
          _buildWeeklyReport(),
          _buildMonthlyReport(),
        ],
      ),
    );
  }

  // ---------------- Daily Report ----------------
  Widget _buildDailyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Date Row (simple mockup)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chevron_left, color: Colors.white54),
              const SizedBox(width: 10),
              for (int i = 9; i <= 15; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    "$i",
                    style: TextStyle(
                      color: i == 12 ? Colors.white : Colors.white54,
                      fontWeight: i == 12 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),

          const SizedBox(height: 30),

          // Title
          const Text(
            "수면 성취",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "목표 수면 대비 실제 수면 비율",
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 30),

          // Circular Progress
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 15.0,
            percent: 0.76,
            center: const Text(
              "76%",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            progressColor: Color(0xFFAEC6CF),
            backgroundColor: Colors.white24,
            circularStrokeCap: CircularStrokeCap.round,
          ),

          const SizedBox(height: 40),

          // Info Card
          _infoCard([
            _infoRow("목표 수면 시간", "00:30 AM - 8:00 AM"),
            _infoRow("실제 수면 시간", "1:07 AM - 8:00 AM"),
            _infoRow("수면 만족도 평가", "보통"),
          ]),

          const SizedBox(height: 20),

          // Daily Feedback Box
          _infoCard([
            const Text("일간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),

          const SizedBox(height: 20),

          // Time Capsule Box
          _infoCard([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("이 날의 타임캡슐", style: TextStyle(fontSize: 16)),
                Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ], height: 60),
        ],
      ),
    );
  }

  // ---------------- Weekly Report ----------------
  Widget _buildWeeklyReport() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "2025년 8월 9일 - 8월 15일",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) {
                        if (value == 0) {
                          return const Text(
                            "0h",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }
                        if (value == 2.5) {
                          return const Text(
                            "2h30m",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }
                        if (value == 5) {
                          return const Text(
                            "5h",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }
                        if (value == 7.5) {
                          return const Text(
                            "7h30m",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = ["토", "일", "월", "화", "수", "목", "금"];
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(color: Colors.white70),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barData(0, 1.2),
                  _barData(1, 3.5),
                  _barData(2, 7.5),
                  _barData(3, 2.5, highlighted: true),
                  _barData(4, 5.0),
                  _barData(5, 3.5),
                  _barData(6, 2.8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _infoCard([
            _infoRow("평균 수면 시간", "5h 30m"),
            _infoRow("가장 긴 수면", "1:07 AM - 8:00 AM"),
            _infoRow("가장 짧은 수면", "3:07 AM - 9:00 AM"),
            _infoRow("평균 수면 만족도", "보통"),
          ]),
          const SizedBox(height: 10),
          _infoCard([
            const Text("주간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),
        ],
      ),
    );
  }

  BarChartGroupData _barData(int x, double y, {bool highlighted = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: highlighted ? Color(0xFFAEC6CF) : Colors.grey[600],
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // ---------------- Monthly Report ----------------
  Widget _buildMonthlyReport() {
    return const Center(
      child: Text("월간 리포트", style: TextStyle(color: Colors.white)),
    );
  }

  // ---------------- UI Helpers ----------------
  Widget _infoCard(List<Widget> children, {double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
