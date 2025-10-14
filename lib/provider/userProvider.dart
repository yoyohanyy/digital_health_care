import 'package:flutter/material.dart';
import '../DTO/userDTO.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(User newUser) {
    _user = newUser;
    notifyListeners(); // UI 자동 갱신
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
