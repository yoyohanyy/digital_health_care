import 'dart:async';
import 'package:flutter/material.dart';
import 'letterPage.dart';

class HomePage extends StatefulWidget {
  final TimeOfDay wakeUpTime;
  final TimeOfDay bedTime;
  final Function(TimeOfDay, TimeOfDay) onTimesChanged;

  const HomePage({
    super.key,
    required this.wakeUpTime,
    required this.bedTime,
    required this.onTimesChanged,
  });

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
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft -= const Duration(seconds: 1);
          }
        });
      }
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
            initialWakeUpTime: widget.wakeUpTime,
            initialBedTime: widget.bedTime,
            onSave: (newWakeUpTime, newBedTime) {
              widget.onTimesChanged(newWakeUpTime, newBedTime);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _formatTimeOfDay(widget.bedTime),
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
                "설정 기상 시간 : ${_formatTimeOfDay(widget.wakeUpTime)}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
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
