import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/healthService.dart';

class ReportPage extends StatefulWidget {
  final TimeOfDay wakeUpTime;
  final TimeOfDay bedTime;

  const ReportPage({
    super.key,
    required this.wakeUpTime,
    required this.bedTime,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService();
  String _sleepDataString = "데이터 없음";
  int _actualSleepMinutes = 0; // 실제 수면 시간 (분)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSleepData();
  }

  Future<void> _fetchSleepData() async {
    await _healthService.authorize();
    List<HealthDataPoint> sleepData = await _healthService.getSleepData();
    int totalMinutes = 0;
    for (var point in sleepData) {
      if (point.type == HealthDataType.SLEEP_SESSION) {
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        totalMinutes += duration;
      }
    }
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (mounted) {
      setState(() {
        if (minutes == 0) {
          _actualSleepMinutes = totalMinutes;
          _sleepDataString = "${hours}시간";
        } else {
          _sleepDataString = "${hours}시간 ${minutes}분";
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('a h:mm', 'ko_KR').format(dt);
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

  Widget _buildDailyReport() {
    final bedTimeString = _formatTimeOfDay(widget.bedTime);
    final wakeUpTimeString = _formatTimeOfDay(widget.wakeUpTime);
    final targetSleepTimeString = '$bedTimeString - $wakeUpTimeString';

    // 2. 목표 수면 시간을 분 단위로 계산
    final now = DateTime.now();
    DateTime bedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.bedTime.hour,
      widget.bedTime.minute,
    );
    DateTime wakeUpDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.wakeUpTime.hour,
      widget.wakeUpTime.minute,
    );

    // 취침 시간이 기상 시간보다 늦은 경우 (예: 오후 11시 취침, 오전 7시 기상)
    // 기상 시간을 다음 날로 처리
    if (wakeUpDateTime.isBefore(bedDateTime)) {
      wakeUpDateTime = wakeUpDateTime.add(const Duration(days: 1));
    }
    // 목표 수면 시간(분)
    final double targetSleepMinutes =
        wakeUpDateTime.difference(bedDateTime).inMinutes.toDouble();

    // 3. 달성률(%) 계산
    double percent = 0.0;
    // 목표 수면 시간이 0보다 클 때만 계산 (0으로 나누기 방지)
    if (targetSleepMinutes > 0) {
      percent = _actualSleepMinutes / targetSleepMinutes;
    }
    // NaN(Not a Number) 이나 음수가 되는 경우를 방지
    if (percent.isNaN || percent.isNegative) {
      percent = 0.0;
    }
    // 화면에 표시할 퍼센트 값 (반올림)
    final int displayPercent = (percent * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 15.0,
            percent: percent > 1.0 ? 1.0 : percent,
            center: Text(
              "$displayPercent%",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            progressColor: const Color(0xFFAEC6CF),
            backgroundColor: Colors.white24,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 40),
          _infoCard([
            _infoRow("목표 수면 시간", targetSleepTimeString),
            _infoRow("실제 수면 시간", _sleepDataString),
            _infoRow("수면 만족도 평가", "보통"),
          ]),
          const SizedBox(height: 20),
          _infoCard([
            const Text("일간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),
          const SizedBox(height: 20),
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
                        if (value % 2.5 == 0) {
                          return Text(
                            "${value.toInt()}h",
                            style: const TextStyle(
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
            _infoRow("가장 긴 수면", "1:07 AM - 8:30 AM"),
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
          color: highlighted ? const Color(0xFFAEC6CF) : Colors.grey[600],
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: DateTime(2025, 9, 1),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle: TextStyle(color: Colors.white70),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFAEC6CF),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          _infoCard([
            _infoRow("평균 수면 시간", "5h 30m"),
            _infoRow("가장 긴 수면", "1:07 AM - 8:30 AM"),
            _infoRow("가장 짧은 수면", "3:07 AM - 9:00 AM"),
            _infoRow("평균 수면 만족도", "보통"),
          ]),
          const SizedBox(height: 10),
          _infoCard([
            const Text("월간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),
        ],
      ),
    );
  }

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
