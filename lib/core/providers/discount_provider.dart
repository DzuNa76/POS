import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountSettingsProvider extends ChangeNotifier {
  bool _isDiscountEnabled = true;
  double _maxDiscountPercentage = 100.0;
  
  bool get isDiscountEnabled => _isDiscountEnabled;
  double get maxDiscountPercentage => _maxDiscountPercentage;
  
  DiscountSettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDiscountEnabled = prefs.getBool('isDiscountEnabled') ?? true;
    _maxDiscountPercentage = prefs.getDouble('maxDiscountPercentage') ?? 100.0;
    notifyListeners();
  }
  
  Future<void> setDiscountEnabled(bool value) async {
    _isDiscountEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDiscountEnabled', value);
    notifyListeners();
  }
  
  Future<void> setMaxDiscountPercentage(double value) async {
    _maxDiscountPercentage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maxDiscountPercentage', value);
    notifyListeners();
  }
}