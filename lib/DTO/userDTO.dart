import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id; // 카카오 로그인 userId
  final String authCode; // 카카오 로그인 인증 코드
  final String chatbotId;
  final String nickname;
  final String profileImage;
  final String sleepStartTime;         // 사용자가 설정한 목표 수면 시작 시간 (HH:mm)
  final String recommendedWakeUpTime;  // 앱이 추천하는 기상 시간 (HH:mm)


  User({
    required this.id,
    required this.authCode,
    required this.chatbotId,
    required this.nickname,
    required this.profileImage,
    required this.sleepStartTime,
    required this.recommendedWakeUpTime,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      authCode: map['authCode'] ?? '',
      chatbotId: map['chatbotId'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImage: map['profileImage'] ?? '',
      sleepStartTime: map['sleepStartTime'] ?? '',
      recommendedWakeUpTime: map['recommendedWakeUpTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authCode': authCode,
      'chatbotId': chatbotId,
      'nickname': nickname,
      'profileImage': profileImage,
      'sleepStartTime': sleepStartTime,
      'recommendedWakeUpTime': recommendedWakeUpTime,
    };
  }
}
