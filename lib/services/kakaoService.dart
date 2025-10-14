import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoService {
  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    try {
      AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
      print("토큰 유효기간: ${tokenInfo.expiresIn}초");
      return tokenInfo.expiresIn > 0;
    } catch (e) {
      return false;
    }
  }

  /// 로그인
  Future<bool> login() async {
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kakaoToken', token.accessToken);

      // 로그인 성공 후 사용자 정보 가져오기
      await saveUserInfo();
      print("로그인 성공");
      return true;
    } catch (e) {
      print("로그인 실패: $e");
      return false;
    }
  }

  /// 앱 재시작 후 토큰으로 로그인 상태 확인
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('kakaoToken');
    if (token != null) {
      try {
        await UserApi.instance.accessTokenInfo(); // 토큰 유효성 확인
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kakaoToken');
      print("로그아웃 완료");
    } catch (e) {
      print("로그아웃 실패: $e");
    }
  }

  /// Firestore에 사용자 정보 저장
  Future<void> saveUserInfo() async {
    try {
      User user = await UserApi.instance.me();

      String userId = user.id.toString();
      String? profileImage = user.kakaoAccount?.profile?.profileImageUrl;
      String? nickname = user.kakaoAccount?.profile?.nickname;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nickname': nickname,
        'profileImage': profileImage,
        'lastLogin': DateTime.now(),
        'sleepStartTime': '22:00',         // 기본값 설정
        'recommendedWakeUpTime': '06:00',  // 기본값 설정
      }, SetOptions(merge: true));

      print("✅ 사용자 정보 저장 완료");
    } catch (e) {
      print("❌ 사용자 정보 저장 실패: $e");
    }
  }
}
