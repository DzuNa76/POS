import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String _token = '';
  String _fullName = '';
  bool _isLoading = true;

  String get token => _token;
  String get fullName => _fullName;
  bool get isAuthenticated => _token.isNotEmpty;
  bool get isLoading => _isLoading;

  AuthProvider() {
    loadToken(); // Cek token saat provider dibuat
  }

  Future<void> setToken(String token, {String? fullName}) async {
    _token = token;
    if (fullName != null) _fullName = fullName; // Simpan fullName juga

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (fullName != null) await prefs.setString('auth_full_name', fullName);

    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    _fullName = prefs.getString('auth_full_name') ?? ''; // Load fullName juga
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String? token, {String? fullName}) async {
    if (token == null || token.isEmpty) return; // Cegah error jika token kosong

    _token = token;
    if (fullName != null) _fullName = fullName; // Simpan fullName jika ada

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (fullName != null)
      await prefs.setString('auth_full_name', fullName); // Simpan fullName juga

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_full_name'); // Hapus fullName juga
    _token = '';
    _fullName = '';
    notifyListeners();
  }
}
