import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigService {
  static late final Map<String, dynamic> _config;
  static late final Map<String, dynamic> _dataExtension;

  static Future<void> load() async {
    final String data =
        await rootBundle.loadString('assets/config/config.json');
    final List<dynamic> allConfigs = jsonDecode(data);

    final matchedConfig = allConfigs.firstWhere(
      (item) => item['is_using'] == 1,
      orElse: () => throw Exception('No active config (is_using: 1) found'),
    );

    _config = matchedConfig['config'] as Map<String, dynamic>;
    _dataExtension = matchedConfig['data_extension'] as Map<String, dynamic>;
  }

  static bool get isCustomerMandatory =>
      _config['is_customer_mandatory'] ?? false;
  static bool get isUsingOutlet => _config['is_using_outlet'] ?? false;
  static bool get isUsingDiscount => _config['is_using_discount'] ?? false;
  static bool get isUsingVoucher => _config['is_using_voucher'] ?? false;
  static bool get isUsingPaymentChannel =>
      _config['is_using_payment_channel'] ?? false;
  static bool get isUsingCheckStock => _config['is_using_check_stock'] ?? false;
  static bool get isUsingListProductTherapist =>
      _config['is_using_therapist'] ?? false;
  static bool get isUsingListProductDiscountPerItem =>
      _config['is_using_list_product_discount_per_item'] ?? false;
  static bool get isUsingQtyItem => _config['is_using_qty_item'] ?? false;
  static String get therapistUrl => _config['therapist'] ?? '';
  static bool get isUsingKasbon => _config['is_using_kasbon'] ?? false;
  static String get kasbonAccount => _dataExtension['kasbon_account'] ?? '';
  static String get logo => _config['logo'] ?? '';
}
