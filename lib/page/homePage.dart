import 'dart:async';
import 'package:flutter/material.dart';
import 'letterPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/userProvider.dart'; // ✅ UserProvider import
import '../provider/sleepProvider.dart';
import '../DTO/sleepRecordDTO.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  // --- 상태 변수 추가 ---
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 0, minute: 0);
  // ---------------------

  @override
  void initState() {
    super.initState();
    _loadTimes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<SleepRecordProvider>(
          context,
          listen: false,
        ).fetchRecords(user.id, days: 7);
      }
    });

    // ✅ Timer that updates _timeLeft every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _updateTimeLeft();
      });
    });
  }

  // ✅ Helper: calculate remaining time until bedtime
  void _updateTimeLeft() {
    final now = DateTime.now();
    final bedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _bedTime.hour,
      _bedTime.minute,
    );

    // If bedtime already passed today, set to tomorrow
    DateTime nextBedTime =
        bedDateTime.isAfter(now)
            ? bedDateTime
            : bedDateTime.add(const Duration(days: 1));

    _timeLeft = nextBedTime.difference(now);
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final wakeUpHour = prefs.getInt('wakeUpHour') ?? _wakeUpTime.hour;
      final wakeUpMinute = prefs.getInt('wakeUpMinute') ?? _wakeUpTime.minute;
      _wakeUpTime = TimeOfDay(hour: wakeUpHour, minute: wakeUpMinute);

      final bedTimeHour = prefs.getInt('bedTimeHour') ?? _bedTime.hour;
      final bedTimeMinute = prefs.getInt('bedTimeMinute') ?? _bedTime.minute;
      _bedTime = TimeOfDay(hour: bedTimeHour, minute: bedTimeMinute);

      _updateTimeLeft(); // ✅ initialize timeLeft when loading
    });
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDurationDiff(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    return "${hours}시간 ${minutes}분";
  }

  String _formatSleepDuration(double totalHours) {
    int hours = totalHours.floor();
    int minutes = ((totalHours - hours) * 60).round();
    return "${hours}시간 ${minutes}분";
  }

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wakeUpHour', _wakeUpTime.hour);
    await prefs.setInt('wakeUpMinute', _wakeUpTime.minute);
    await prefs.setInt('bedTimeHour', _bedTime.hour);
    await prefs.setInt('bedTimeMinute', _bedTime.minute);
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

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final period = tod.period == DayPeriod.am ? "오전" : "오후";
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    return "$period ${hour.toString().padLeft(2, ' ')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  void _showTimeSettingsSheet() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TimeSettingsSheet(
            initialWakeUpTime: _wakeUpTime,
            initialBedTime: _bedTime,
            onSave: (newWakeUpTime, newBedTime) {
              setState(() {
                _wakeUpTime = newWakeUpTime;
                _bedTime = newBedTime;
                _updateTimeLeft(); // ✅ recalc timeLeft on save
              });
              _saveTimes();
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildSleepInfoContent(BuildContext context) {
    final sleepProvider = Provider.of<SleepRecordProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final records = sleepProvider.records;

    // 1. 오늘 날짜와 어제 날짜 구하기
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // 2. Provider의 records 리스트에서 오늘/어제 기록 찾기
    // firstWhere를 쓰되, 없으면 null을 반환하도록 orElse 처리 (혹은 try-catch)
    SleepRecord? todayRecord;
    SleepRecord? yesterdayRecord;

    try {
      todayRecord = records.firstWhere(
        (r) => _isSameDate(r.date, todayDate),
        // Provider 로직상 데이터가 없으면 empty 객체가 있을 수 있으므로 null 처리는 사실상 불필요할 수 있으나 안전하게 작성
      );
    } catch (e) {
      todayRecord = null;
    }

    try {
      yesterdayRecord = records.firstWhere(
        (r) => _isSameDate(r.date, yesterdayDate),
      );
    } catch (e) {
      yesterdayRecord = null;
    }

    // 3. 데이터 유효성 검사
    // SleepRecord.empty()로 생성된 객체는 startTime이 null입니다.
    // 따라서 startTime이 null이 아니어야 "유효한 데이터"로 봅니다.
    bool hasTodayData =
        todayRecord != null &&
        todayRecord.startTime != null &&
        todayRecord.totalHours > 0;
    bool hasYesterdayData =
        yesterdayRecord != null &&
        yesterdayRecord.startTime != null &&
        yesterdayRecord.totalHours > 0;

    // --- CASE 1: 오늘의 데이터가 없는 경우 ---
    if (!hasTodayData) {
      return [
        Text(
          "${userProvider.user?.nickname ?? "사용자"}님의 오늘 총 수면 시간은",
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        const Text(
          "오늘의 수면 시간이\n업로드가 되지 않았습니다.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
      ];
    }

    // --- CASE 2: 오늘의 데이터가 있는 경우 (기본 표시) ---
    List<Widget> content = [
      Text(
        "${userProvider.user?.nickname ?? "사용자"}님의 오늘 총 수면 시간은",
        style: const TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 10),
      Text(
        "총 ${_formatSleepDuration(todayRecord!.totalHours)}",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    // --- CASE 3: 어제의 데이터가 있어서 비교가 가능한 경우 ---
    if (hasYesterdayData) {
      // double(시간) 차이를 계산
      double diffHours = todayRecord.totalHours - yesterdayRecord!.totalHours;

      // 계산을 위해 Duration으로 변환
      int diffInMinutes = (diffHours * 60).round();
      Duration diffDuration = Duration(minutes: diffInMinutes.abs());

      bool isMore = diffInMinutes >= 0; // 오늘 더 많이 잤거나 같음

      String compareText;
      if (diffInMinutes == 0) {
        compareText = "어제와 수면 시간이 같아요.";
      } else {
        compareText =
            "어제보다 ${_formatDurationDiff(diffDuration)} ${isMore ? '더 잤어요!' : '적어요!'}";
      }

      content.add(const SizedBox(height: 5));
      content.add(
        Text(compareText, style: const TextStyle(color: Colors.white70)),
      );
    }
    // 어제 데이터가 없으면 비교 텍스트는 추가되지 않습니다.

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final sleepProvider = Provider.of<SleepRecordProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        title: const Text("홈"),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "안녕하세요 ${user?.nickname ?? "사용자"}님!",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),

            _infoCard([
              Text(
                "오늘 ${user?.nickname ?? "사용자"}님의 추천 취침 시간은",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                _formatTimeOfDay(_bedTime),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("수면 시작 까지", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(
                _formatDuration(_timeLeft),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "설정 기상 시간 : ${_formatTimeOfDay(_wakeUpTime)}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: _showTimeSettingsSheet,
                child: const Text("수정하기"),
              ),
            ]),

            const SizedBox(height: 20),

            sleepProvider.isLoading
                ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
                : _infoCard(
                  // 만들어둔 함수를 호출하여 실제 데이터를 넣어줍니다.
                  _buildSleepInfoContent(context),
                ),

            const SizedBox(height: 20),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LetterPage()),
                );
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: _infoCard([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "어제의 내가 오늘의 나에게",
                      style: TextStyle(color: Colors.white),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ]),
            ),
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
        color: const Color(0xFF2D3748),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }
}

// +++ TimeSettingsSheet 그대로 유지 +++
class TimeSettingsSheet extends StatefulWidget {
  final TimeOfDay initialWakeUpTime;
  final TimeOfDay initialBedTime;
  final Function(TimeOfDay, TimeOfDay) onSave;

  const TimeSettingsSheet({
    super.key,
    required this.initialWakeUpTime,
    required this.initialBedTime,
    required this.onSave,
  });

  @override
  State<TimeSettingsSheet> createState() => _TimeSettingsSheetState();
}

class _TimeSettingsSheetState extends State<TimeSettingsSheet> {
  late TimeOfDay _wakeUpTime;
  late TimeOfDay _bedTime;
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _wakeUpTime = widget.initialWakeUpTime;
    _bedTime = widget.initialBedTime;
  }

  String _formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, ' ')}:$minute';
  }

  String _formatTimeValue(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _bedTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        // Theme 위젯으로 감싸서 색상을 덮어씁니다.
        return Theme(
          data: ThemeData.dark().copyWith(
            // ----------------------------------------------------
            // 여기에 원하는 색상을 지정하세요
            // ----------------------------------------------------
            colorScheme: const ColorScheme.dark(
              // ✅ 주요 색상 (선택된 숫자 배경, 시계 상단 헤더)
              primary: Color(0xFF4A5568),
              // ✅ primary 색상 위의 텍스트 (예: 헤더의 시간)
              onPrimary: Colors.white,
              // ✅ 다이얼로그 전체 배경색
              surface: Color(0xFF2D3748),
              // ✅ 배경색 위의 텍스트 (예: 시계 다이얼 숫자)
              onSurface: Colors.white,
            ),
            // ✅ "확인", "취소" 버튼 텍스트 색상
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.tealAccent, // 앱의 강조색과 맞추면 좋습니다.
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _bedTime = picked;
        }
      });
    }
  }

  List<TimeOfDay> _getRecommendedTimes() {
    final now = DateTime.now();
    final wakeUpDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeUpTime.hour,
      _wakeUpTime.minute,
    );
    final recommendedTime1 = wakeUpDateTime.subtract(
      const Duration(hours: 7, minutes: 30),
    );
    return [TimeOfDay.fromDateTime(recommendedTime1)];
  }

  @override
  Widget build(BuildContext context) {
    final recommendedTimes = _getRecommendedTimes();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(20),
          ),

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeSelector(
                  "기상 시간 설정",
                  _wakeUpTime,
                  () => _selectTime(context, true),
                ),
                const SizedBox(height: 16),
                _buildTimeSelector(
                  "취침 시간 설정",
                  _bedTime,
                  () => _selectTime(context, false),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8.0, // 가로 아이템 사이 간격
                  runSpacing: 4.0, // 세로 줄 사이 간격
                  crossAxisAlignment: WrapCrossAlignment.center, // 세로 정렬

                  children: [
                    const Text(
                      "추천 시간:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    // const SizedBox(width: 8), // Wrap의 spacing이 대신함
                    ...recommendedTimes.map((time) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionChip(
                          label: Text(_formatTime(time)),
                          backgroundColor: const Color(0xFF2D3748),
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _bedTime = time;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isNotificationEnabled,
                      onChanged: (bool? value) {
                        setState(() {
                          _isNotificationEnabled = value ?? false;
                        });
                      },
                      activeColor: Colors.tealAccent,
                      checkColor: Colors.black,
                    ),
                    const Text(
                      "설정 취침 시간에 알림 받기",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_wakeUpTime, _bedTime);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3748),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    "저장하기",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Icon(Icons.access_time, color: Colors.white54),
                const SizedBox(width: 16),
                Text(
                  _formatTime(time).split(' ')[0],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeValue(time),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
