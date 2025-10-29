import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:table_calendar/table_calendar.dart';
import '../DTO/sleepRecordDTO.dart';
import '../provider/sleepProvider.dart';
import '../services/healthService.dart';
import '../services/firebaseService.dart';
import 'sharePage.dart';
import '../provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService();
  final FirebaseService _firebaseService = FirebaseService();

  Health health = Health();
  String _sleepDataString = "데이터 없음";
  double _totalHours = 0.0;
  DateTime? _sleepStartTime;
  DateTime? _sleepEndTime;
  double _deepSleep = 0.0;
  bool _isLoading = true;
  int _currentTabIndex = 0;
  String _targetSleepTimeString = "00:00 AM - 00:00 AM";
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentWeekStart;
  double _targetSleepDurationHours = 8.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _currentWeekStart = _getStartOfWeek(_selectedDate);

    _loadSleepDataForDate(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSleepRecords();
      await _loadTargetSleepTime();
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  Future<void> _loadTargetSleepTime() async {
    final prefs = await SharedPreferences.getInstance();

    final wakeUpHour = prefs.getInt('wakeUpHour') ?? 8;
    final wakeUpMinute = prefs.getInt('wakeUpMinute') ?? 0;
    final bedTimeHour = prefs.getInt('bedTimeHour') ?? 0;
    final bedTimeMinute = prefs.getInt('bedTimeMinute') ?? 0;

    final wakeUpTime = TimeOfDay(hour: wakeUpHour, minute: wakeUpMinute);
    final bedTime = TimeOfDay(hour: bedTimeHour, minute: bedTimeMinute);

    int bedTimeMinutes = bedTime.hour * 60 + bedTime.minute;
    int wakeUpMinutes = wakeUpTime.hour * 60 + wakeUpTime.minute;
    int duration =
        bedTimeMinutes > wakeUpMinutes
            ? (24 * 60 - bedTimeMinutes) + wakeUpMinutes
            : wakeUpMinutes - bedTimeMinutes;

    setState(() {
      _targetSleepTimeString =
          '${_formatTimeOfDay(bedTime)} - ${_formatTimeOfDay(wakeUpTime)}';
      _targetSleepDurationHours = duration / 60.0;
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a', 'en_US').format(dt);
  }

  Future<void> _loadSleepDataForDate(DateTime date) async {
    final sleepInfo = await _healthService.fetchDailySleepDataForDate(date);

    setState(() {
      _sleepDataString = sleepInfo['sleepString'] ?? "데이터 없음";
      _totalHours = sleepInfo['totalHours'];
      _sleepStartTime = sleepInfo['startTime'];
      _sleepEndTime = sleepInfo['endTime'];
      _deepSleep = sleepInfo['deepSleep'];
    });
    /* 버튼을 누를 시 저장이 되게 하는 것이 오류가 없을 듯 합니다.
    if (_sleepStartTime != null && _sleepEndTime != null) {
      await _firebaseService.saveTodaySleepData(
        "test_user_123",
        {
          'startTime': _sleepStartTime,
          'endTime': _sleepEndTime,
          'totalMinutes': _totalHours * 60,
          'deepSleep': _deepSleep,
        },
      );
    }
  */
  }

  // ------------------- Firebase 저장 함수 (신규 추가) -------------------
  Future<void> _saveSleepDataToFirebase() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 1. 로그인한 사용자 ID 가져오기
    if (userProvider.user == null) {
      return;
    }
    String userId = userProvider.user!.id;

    // 2. 저장할 HealthService 데이터가 있는지 확인
    if (_sleepStartTime != null && _sleepEndTime != null) {
      // 3. 저장할 데이터 맵 구성
      // (기존 _loadSleepDataForDate의 주석 처리된 로직과 동일하게 구성)
      final Map<String, dynamic> sleepData = {
        'startTime': _sleepStartTime,
        'endTime': _sleepEndTime,
        'totalMinutes': _totalHours * 60,
        'deepSleep': _deepSleep, // 요청하신 대로 'deepSleep' 명칭 사용
      };

      try {
        // 4. Firebase 서비스 호출
        await _firebaseService.saveTodaySleepData(userId, sleepData);
        // 6. (중요) 저장 후 최신 데이터를 다시 불러옵니다.
        // 이렇게 하면 주간/월간 탭의 데이터도 즉시 새로고침됩니다.
        await _loadSleepRecords();
      } catch (e) {
        // 7. 실패 피드백
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("데이터 저장에 실패했습니다: $e")));
      }
    }
  }

  Future<void> _loadSleepRecords() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sleepProvider = Provider.of<SleepRecordProvider>(
      context,
      listen: false,
    );
    await sleepProvider.fetchRecords(userProvider.user!.id, days: 30);
    setState(() {
      _isLoading = false;
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadSleepDataForDate(date);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepRecordProvider>(context);
    final records = sleepProvider.records;

    // 오늘 record 가져오기
    final todayRecord = records.firstWhere(
      (r) => _isSameDay(r.date, _selectedDate),
      orElse: () => SleepRecord.empty(_selectedDate),
    );

    // 주간 Map 생성
    Map<DateTime, double> weeklySleep = {};
    for (int i = 0; i < 7; i++) {
      DateTime day = _currentWeekStart.add(Duration(days: i));
      final r = records.firstWhere(
        (rec) => _isSameDay(rec.date, day),
        orElse: () => SleepRecord.empty(day),
      );
      weeklySleep[day] = r.totalHours.toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        title: const Text(
          "리포트",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: null, // 필요시 SharePage 연결
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "일간"), Tab(text: "주간"), Tab(text: "월간")],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(todayRecord, weeklySleep),
          _buildWeeklyReport(weeklySleep),
          _buildMonthlyReport(),
        ],
      ),
    );
  }

  // ---------------- Daily Report ----------------
  Widget _buildDailyReport(
    SleepRecord todayRecord,
    Map<DateTime, double> weeklySleep,
  ) {
    List<DateTime> weekDays = List.generate(
      7,
      (i) => _currentWeekStart.add(Duration(days: i)),
    );

    final double sleepPercent =
        (_targetSleepDurationHours > 0)
            ? (_totalHours / _targetSleepDurationHours).clamp(0.0, 1.0)
            : 0.0;
    final String percentText = "${(sleepPercent * 100).toStringAsFixed(0)}%";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: _goToPreviousWeek,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var day in weekDays)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(day),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            children: [
                              Text(
                                DateFormat.E('ko_KR').format(day),
                                style: TextStyle(
                                  color:
                                      _isSameDay(day, _selectedDate)
                                          ? Colors.white
                                          : Colors.white54,
                                  fontWeight:
                                      _isSameDay(day, _selectedDate)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${day.day}",
                                style: TextStyle(
                                  color:
                                      _isSameDay(day, _selectedDate)
                                          ? Colors.white
                                          : Colors.white54,
                                  fontWeight:
                                      _isSameDay(day, _selectedDate)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              if (_isSameDay(day, _selectedDate))
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: _goToNextWeek,
              ),
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
            percent: sleepPercent,
            center: Text(
              percentText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            progressColor: const Color(0xFFAEC6CF),
            backgroundColor: Colors.white24,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 40),
          _infoCard([
            _infoRow("선택한 날짜", DateFormat('yyyy.MM.dd').format(_selectedDate)),
            _infoRow("목표 수면 시간", _targetSleepTimeString),
            _infoRow("실제 수면 시간", "${todayRecord.totalHours}시간"),
            _infoRow("수면 만족도 평가", "보통"),
          ]),
          const SizedBox(height: 20),
          _infoCard([
            const Text("일간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),

          const SizedBox(height: 30), // 버튼 위 여백
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAEC6CF), // 테마 색상과 유사하게
              foregroundColor: Colors.black, // 텍스트 색상
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _saveSleepDataToFirebase, // 위에서 추가한 함수 연결
            child: const Text("저장"),
          ),
          const SizedBox(height: 20), // 버튼 아래 여백
        ],
      ),
    );
  }

  // ---------------- Weekly Report ----------------
  Widget _buildWeeklyReport(Map<DateTime, double> weeklySleep) {
    DateTime weekStart = _currentWeekStart;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text("이번 주 수면 데이터", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : BarChart(
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
                                int index = value.toInt();
                                DateTime date = weekStart.add(
                                  Duration(days: index),
                                );
                                String label = DateFormat.E(
                                  'ko_KR',
                                ).format(date);
                                return Text(
                                  label,
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
                        barGroups: List.generate(7, (i) {
                          DateTime date = weekStart.add(Duration(days: i));
                          double sleepHours = weeklySleep[date] ?? 0.0;
                          return _barData(i, sleepHours);
                        }),
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

  // ---------------- Monthly Report ----------------
  // ---------------- Monthly Report ----------------
  Widget _buildMonthlyReport() {
    final sleepProvider = Provider.of<SleepRecordProvider>(context);
    final records = sleepProvider.records;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // 월간 Map 생성 (시간 제거)
    Map<DateTime, double> monthlySleep = {};
    for (int i = 0; i < daysInMonth; i++) {
      DateTime day = DateTime(now.year, now.month, 1).add(Duration(days: i));
      final record = records.firstWhere(
        (r) =>
            r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day,
        orElse: () => SleepRecord.empty(day),
      );
      monthlySleep[DateTime(day.year, day.month, day.day)] =
          record.totalHours.toDouble();
    }

    // 월간 통계 계산
    final sleepValues = monthlySleep.values.where((v) => v > 0).toList();
    double avgSleep =
        sleepValues.isNotEmpty
            ? sleepValues.reduce((a, b) => a + b) / sleepValues.length
            : 0.0;
    double maxSleep =
        sleepValues.isNotEmpty
            ? sleepValues.reduce((a, b) => a > b ? a : b)
            : 0.0;
    double minSleep =
        sleepValues.isNotEmpty
            ? sleepValues.reduce((a, b) => a < b ? a : b)
            : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            selectedDayPredicate: (day) => _isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              _loadSleepDataForDate(selectedDay);
              _tabController.animateTo(0); // 일간 탭으로 이동
            },
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
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Color(0xFFAEC6CF),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                DateTime key = DateTime(day.year, day.month, day.day);
                double sleepHours = monthlySleep[key] ?? 0.0;
                if (sleepHours > 0) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          // 월간 통계 카드
          _infoCard([
            _infoRow("평균 수면 시간", "${avgSleep.toStringAsFixed(1)}h"),
            _infoRow("최장 수면 시간", "${maxSleep.toStringAsFixed(1)}h"),
            _infoRow("최단 수면 시간", "${minSleep.toStringAsFixed(1)}h"),
          ]),
          const SizedBox(height: 10),
          // 월간 피드백 카드
          _infoCard([
            const Text("월간 피드백", style: TextStyle(fontSize: 16)),
          ], height: 80),
        ],
      ),
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
