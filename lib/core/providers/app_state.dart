import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'voucher_provider.dart';
import 'user_provider.dart';

class AppState with ChangeNotifier {
  final AuthProvider authProvider = AuthProvider();
  final CartProvider cartProvider = CartProvider();
  final VoucherProvider voucherProvider = VoucherProvider();
  final UserProvider userProvider = UserProvider();

  bool _isDataReady = false;

  bool get isDataReady => _isDataReady;

  String _customerName = "Guest";

  String get customerName => _customerName;

  List<CartItem> _saveCartItem = [];

  Future<void> saveCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartItemsJson =
        _saveCartItem.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('cartItems', cartItemsJson);
  }

  Future<void> loadCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsJson = prefs.getStringList('cartItems');
    if (cartItemsJson != null) {
      _saveCartItem = cartItemsJson
          .map((itemJson) => CartItem.fromJson(jsonDecode(itemJson)))
          .toList();
      notifyListeners();
    }
  }

  void updateCustomerName(String name) {
    _customerName = name.isNotEmpty ? name : "Guest";
    notifyListeners();
  }

  String _orderType = "Dine In"; // Default order type

  String get orderType => _orderType;

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setDataReady(bool value) {
    _isDataReady = value;
    notifyListeners();
  }

  void notifyAll() {
    notifyListeners();
  }
}
