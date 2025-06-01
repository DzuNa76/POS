// features/payment/models/payment_data.dart
import 'package:pos/data/models/cart_item.dart';

class PaymentData {
  final String modeOfPayment;
  final int? cashAmount;
  final String? referenceNumber;
  final String? account;
  final int totalTagihan;
  final List<CartItem> orders;
  final String customerName;

  PaymentData({
    required this.modeOfPayment,
    this.cashAmount,
    this.referenceNumber,
    this.account,
    required this.totalTagihan,
    required this.orders,
    required this.customerName,
  });
}

class PaymentResult {
  final bool success;
  final String message;
  final dynamic data;

  PaymentResult({
    required this.success,
    required this.message,
    this.data,
  });
}



// config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://monroe.my.id';
  
  static final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Cookie': 'full_name=Administrator; sid=515976ef5185c5b7f41df98812796f6d8d48c411b4da5bc526384cb6; system_user=yes; user_id=Administrator; user_image=',
  };
  
  // You could add more configuration here like timeout settings, error handling constants, etc.
}