import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/data/models/customer/customer.dart';

class CustomerProvider with ChangeNotifier {
  static const _customerKey = 'saved_customer';

  Customer? _customer;

  Customer? get customer => _customer;

  Future<void> saveCustomer(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerKey, json.encode(customer.toJson()));
    _customer = customer;
    notifyListeners();
  }

  Future<void> loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customerKey);
    if (jsonString != null) {
      _customer = Customer.fromJson(json.decode(jsonString));
      notifyListeners();
    }
  }

  Future<void> deleteCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customerKey);
    _customer = null;
    notifyListeners();
  }
}
