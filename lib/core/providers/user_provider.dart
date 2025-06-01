import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic> _userDetail = {};

  Map<String, dynamic> get userDetail => _userDetail;

  void setUserDetail(Map<String, dynamic> user) {
    _userDetail = user;
    notifyListeners();
  }

  void clearUser() {
    _userDetail = {};
    notifyListeners();
  }
}
