import 'package:flutter/material.dart';

class SharePage extends StatelessWidget {
  // ReportPage로부터 전달받을 변수들
  final double totalSleepHours;
  final double deepSleepHours;
  final double lightSleepHours;
  final int sleepScore;
  final int avgHeartRate;
  final String sleepSatisfaction;
  final int sleepGoalPercent;
  final String dayOfWeek;

  const SharePage({
    super.key,
    // 생성자에서 데이터를 필수로 받도록 required 키워드 추가
    required this.totalSleepHours,
    required this.deepSleepHours,
    required this.lightSleepHours,
    required this.sleepScore,
    required this.avgHeartRate,
    required this.sleepSatisfaction,
    required this.sleepGoalPercent,
    required this.dayOfWeek,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle labelStyle = TextStyle(color: Colors.white70, fontSize: 16);
    const TextStyle valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 48,
      fontWeight: FontWeight.bold,
    );
    const TextStyle unitStyle = TextStyle(color: Colors.white, fontSize: 18);

    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '리포트',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$dayOfWeek 수면', // 👈 전달받은 요일 사용
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalSleepHours.toStringAsFixed(1), // 👈 전달받은 총 수면 시간
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('총 수면 시간', style: unitStyle),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MetricItem(
                      value: deepSleepHours.toStringAsFixed(1),
                      label: '깊은 수면',
                    ), // 👈 깊은 수면
                    MetricItem(
                      value: lightSleepHours.toStringAsFixed(1),
                      label: '얕은 수면',
                    ), // 👈 얕은 수면
                    MetricItem(
                      value: sleepScore.toString(),
                      label: '수면 점수',
                    ), // 👈 수면 점수
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MetricItem(
                      value: sleepSatisfaction,
                      label: '수면 만족도',
                    ), // 👈 수면 만족도
                  ],
                ),
                const SizedBox(height: 60),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '하루 수면 성취',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    const Text('목표 수면 대비 실제 수면 비율', style: labelStyle),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: sleepGoalPercent / 100.0, // 👈 목표 달성률
                            strokeWidth: 15,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6A84A9),
                            ),
                          ),
                          Center(
                            child: Text(
                              '$sleepGoalPercent%', // 👈 목표 달성률
                              style: valueStyle.copyWith(fontSize: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricItem extends StatelessWidget {
  final String value;
  final String label;

  const MetricItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}
