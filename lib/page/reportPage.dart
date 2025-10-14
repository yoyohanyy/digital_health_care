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
  Map<DateTime, double> _weeklySleep = {};
  bool _isLoading = true;
  int _currentTabIndex = 0;
  String _targetSleepTimeString = "00:00 AM - 00:00 AM";

  // 🆕 For dynamic date navigation
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentWeekStart;
  double _targetSleepDurationHours = 8.0; //목표 수면 시간을 저장할 곳

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ 탭 컨트롤러에 리스너 추가
    _tabController.addListener(() {
      // 탭이 변경될 때마다 상태를 업데이트하여 UI를 다시 그리도록 함
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    // ✅ Initialize the current week (Sunday as start)
    _currentWeekStart = _getStartOfWeek(_selectedDate);

    // ✅ Load sleep data
    _loadSleepDataForDate(_selectedDate);

    // Firebase 데이터 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadSleepRecords();
      _loadTargetSleepTime();
    });
  }

  // Helper to get start of the week (Sunday)
  DateTime _getStartOfWeek(DateTime date) {
    // weekday: Monday=1, Sunday=7 → Sunday start = subtract weekday % 7
    return date.subtract(Duration(days: date.weekday % 7));
  }

  Future<void> _loadTargetSleepTime() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 값이 없으면 기본값 사용
    final wakeUpHour = prefs.getInt('wakeUpHour') ?? 8;
    final wakeUpMinute = prefs.getInt('wakeUpMinute') ?? 0;
    final bedTimeHour = prefs.getInt('bedTimeHour') ?? 0;
    final bedTimeMinute = prefs.getInt('bedTimeMinute') ?? 0;

    final wakeUpTime = TimeOfDay(hour: wakeUpHour, minute: wakeUpMinute);
    final bedTime = TimeOfDay(hour: bedTimeHour, minute: bedTimeMinute);

    // ✅ 목표 수면 시간(분) 계산
    int bedTimeInMinutes = bedTime.hour * 60 + bedTime.minute;
    int wakeUpTimeInMinutes = wakeUpTime.hour * 60 + wakeUpTime.minute;

    int durationInMinutes;

    // 취침 시간이 기상 시간보다 늦으면 (예: 23시 취침, 07시 기상)
    if (bedTimeInMinutes > wakeUpTimeInMinutes) {
      durationInMinutes = (24 * 60 - bedTimeInMinutes) + wakeUpTimeInMinutes;
    } else {
      durationInMinutes = wakeUpTimeInMinutes - bedTimeInMinutes;
    }

    setState(() {
      _targetSleepTimeString =
          '${_formatTimeOfDay(bedTime)} - ${_formatTimeOfDay(wakeUpTime)}';

      _targetSleepDurationHours = durationInMinutes / 60.0;
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

    if (_sleepStartTime != null && _sleepEndTime != null) {
      await _firebaseService.saveTodaySleepData(
        "test_user_123", // 실제 로그인한 userId로 교체
        {
          'startTime': _sleepStartTime,
          'endTime': _sleepEndTime,
          'totalMinutes': _totalHours * 60,
          'deepSleep': _deepSleep,
        },
      );
    }
  }

  Future<void> _loadSleepRecords() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sleepProvider = Provider.of<SleepRecordProvider>(
        context, listen: false);
    await sleepProvider.fetchRecords(
        userProvider.user!.id, days: 30); // 최근 30일 데이터 로드
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

  // ---------------- Main ----------------
  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepRecordProvider>(context);
    final records = sleepProvider.records;
    // 🆕 오늘 record 찾기, 없으면 더미 데이터 생성
    final today = _selectedDate;
    SleepRecord todayRecord = records.firstWhere(
          (r) =>
      r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day,
      orElse: () => SleepRecord(
        date: today,
        startTime: today,
        endTime: today,
        totalHours: 0,
        deepSleep: 0,
        satisfaction: 0,
        feedback: '데이터 없음',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      ),
    );

    // 🆕 주간 데이터 Map
    Map<DateTime, double> weeklySleep = {};
    for (int i = 0; i < 7; i++) {
      DateTime day = _currentWeekStart.add(Duration(days: i));
      final r = records.firstWhere(
            (rec) =>
        rec.date.year == day.year &&
            rec.date.month == day.month &&
            rec.date.day == day.day,
        orElse: () => SleepRecord(
          date: day,
          startTime: day,
          endTime: day,
          totalHours: 0,
          deepSleep: 0,
          satisfaction: 0,
          feedback: '데이터 없음',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ),
      );
      weeklySleep[day] = r.totalHours.toDouble();
    }
   // ✅ 로그인된 사용자 정보
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        title: const Text(
          "리포트",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        actions: [
          // '일간' 탭(인덱스 0)일 때만 공유 아이콘을 표시합니다.
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                final double lightSleepHours = (_totalHours - _deepSleep).clamp(
                  0.0,
                  _totalHours,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SharePage(
                          totalSleepHours: _totalHours,
                          deepSleepHours: _deepSleep,
                          lightSleepHours: lightSleepHours,
                          dayOfWeek: DateFormat(
                            'EEEE',
                            'ko_KR',
                          ).format(_selectedDate),
                          sleepScore: 78,
                          avgHeartRate: 98,
                          sleepSatisfaction: "보통",
                          sleepGoalPercent: 76,
                        ),
                  ),
                );
              },
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
          _buildDailyReport(todayRecord),
          _buildWeeklyReport(weeklySleep),
          _buildMonthlyReport(),
        ],
      ),
    );
  }

  // ---------------- Daily Report ----------------
  Widget _buildDailyReport(SleepRecord todayRecord) {
    List<DateTime> weekDays = List.generate(
      7,
      (i) => _currentWeekStart.add(Duration(days: i)),
    );

    // ✅ 수면 목표 달성률 계산
    // _targetSleepDurationHours가 0보다 클 때만 계산 (0으로 나누기 방지)
    final double sleepPercent =
        (_targetSleepDurationHours > 0)
            ? (_totalHours / _targetSleepDurationHours).clamp(
              0.0,
              1.0,
            ) // 0.0과 1.0 사이 값으로 제한
            : 0.0;

    final String percentText = "${(sleepPercent * 100).toStringAsFixed(0)}%";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // 🗓 Dynamic Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: _goToPreviousWeek,
              ),
              Expanded(
                child: Row(
                  // ✅ 7개의 날짜가 공간을 균등하게 나누도록 설정
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var day in weekDays)
                      // ✅ 각각의 날짜 아이템을 Expanded로 감싸서 균등하게 분배
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(day),
                          // 투명한 영역도 터치가 되도록 설정
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            progressColor: Color(0xFFAEC6CF),
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
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: /*_saveSleepData,*/ null,
            child: const Text("저장", style: TextStyle(fontSize: 16)),
          ),
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
  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            focusedDay: DateTime.now(),
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

  // ---------------- UI Helpers ----------------
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
