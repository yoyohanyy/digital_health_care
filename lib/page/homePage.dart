import 'dart:async';
import 'package:flutter/material.dart';
import 'letterPage.dart';

// HomePage는 기존 코드에서 수정된 부분만 확인하시면 됩니다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 9, minutes: 20, seconds: 11);

  // --- 상태 변수 추가 ---
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 0, minute: 0);
  // ---------------------

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

  // 시간 포맷을 위한 함수 추가
  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final period = tod.period == DayPeriod.am ? "오전" : "오후";
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    return "$period ${hour.toString().padLeft(2, ' ')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  // 시간 설정 시트 표시 함수
  void _showTimeSettingsSheet() {
    // 기존 showModalBottomSheet 대신 showDialog를 사용합니다.
    showDialog(
      context: context,
      builder: (context) {
        // Dialog 위젯으로 TimeSettingsSheet를 감싸줍니다.
        return Dialog(
          backgroundColor: Colors.transparent, // 기본 배경을 투명하게
          elevation: 0, // 그림자 제거
          child: TimeSettingsSheet(
            initialWakeUpTime: _wakeUpTime,
            initialBedTime: _bedTime,
            onSave: (newWakeUpTime, newBedTime) {
              setState(() {
                _wakeUpTime = newWakeUpTime;
                _bedTime = newBedTime;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold의 배경색을 어둡게 변경
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        title: const Text("홈"),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0, // AppBar 그림자 제거
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "안녕하세요 동은님!",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),

            _infoCard([
              const Text(
                "오늘 동은님의 추천 취침 시간은",
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
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              // *** 수정된 부분 ***
              TextButton(
                onPressed: _showTimeSettingsSheet,
                child: const Text("수정하기"),
              ),
            ]),

            const SizedBox(height: 20),

            _infoCard([
              const Text(
                "동은님의 오늘 총 수면 시간은",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              const Text(
                "총 5시간 53분",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "어제보다 1시간 3분 적어요!",
                style: TextStyle(color: Colors.white70),
              ),
            ]),

            const SizedBox(height: 20),

            InkWell(
              onTap: () {
                // LetterPage로 화면을 전환합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LetterPage()),
                );
              },
              // 터치 시 배경이 어두워지는 효과를 없애기 위함
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
        color: const Color(0xFF2D3748), // 카드 배경색 변경
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }
}

// +++ 여기서부터 새로 추가된 위젯입니다 +++
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

  // TimeOfDay를 '오전/오후 hh:mm' 형식의 문자열로 변환하는 함수
  String _formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    // 12시간 형식으로 변환 (0시는 12시로 표시)
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, ' ')}:$minute';
  }

  String _formatTimeValue(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // TimePicker를 보여주고 선택된 시간을 상태에 반영하는 함수
  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _bedTime,
      initialEntryMode: TimePickerEntryMode.input, // 숫자 입력 모드로 시작
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

  // 추천 시간을 계산하는 함수
  List<TimeOfDay> _getRecommendedTimes() {
    final now = DateTime.now();
    // TimeOfDay를 DateTime으로 변환하여 계산
    final wakeUpDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeUpTime.hour,
      _wakeUpTime.minute,
    );

    // 기상 시간으로부터 7시간 30분
    final recommendedTime1 = wakeUpDateTime.subtract(
      const Duration(hours: 7, minutes: 30),
    );

    return [TimeOfDay.fromDateTime(recommendedTime1)];
  }

  @override
  Widget build(BuildContext context) {
    final recommendedTimes = _getRecommendedTimes();

    // SafeArea를 사용하여 시스템 UI를 피함
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(20),
          ),
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
              Row(
                children: [
                  const Text("추천 시간:", style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 8),
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
                  }).toList(),
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
                  Navigator.pop(context); // 시트 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3748),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0, // 그림자 제거
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
    );
  }

  // 시간 선택 UI를 만드는 헬퍼 위젯
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
                  _formatTime(time).split(' ')[0], // 오전/오후
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeValue(time), // hh:mm
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
