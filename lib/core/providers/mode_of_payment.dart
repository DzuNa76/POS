import 'package:flutter/material.dart';
import 'package:pos/data/models/mode_of_payment_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ModeOfPaymentProvider with ChangeNotifier {
  List<ModeOfPayment> _modeOfPayments = [];
  String _warehouseName = '';

  List<ModeOfPayment> get modeOfPayments => _modeOfPayments;
  String get warehouseName => _warehouseName;

  ModeOfPaymentProvider() {
    loadModeOfPayments(); // Load data saat provider dibuat
    loadWarehouseName();
  }

  Future<void> setWarehouseName(String name) async {
    _warehouseName = name;
    notifyListeners();
  }

  Future<void> loadWarehouseName() async {
    final prefs = await SharedPreferences.getInstance();
    _warehouseName = prefs.getString('warehouse_name') ?? '';
    notifyListeners();
  }

  Future<void> saveModeOfPayments(List<ModeOfPayment> payments) async {
    _modeOfPayments = payments;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(payments.map((e) => e.toJson()).toList());
    await prefs.setString('mode_of_payments', jsonString);

    notifyListeners();
  }

  Future<void> loadModeOfPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('mode_of_payments');

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _modeOfPayments = jsonData.map((e) => ModeOfPayment.fromJson(e)).toList();
    }

    notifyListeners();
  }
}
