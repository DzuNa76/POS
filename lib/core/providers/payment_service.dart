// features/payment/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos/data/api/api_service.dart';
import 'package:pos/data/models/payment_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl = ApiService.baseUrl;

  String getAccountForPaymentMethod(String? method) {
    switch (method) {
      case "Cash":
        return "1111.001 - Kas Kecil - M";
      case "Credit Card":
        return "1121.001 - Bank BCA - M";
      case "Bank Transfer":
        return "1122.001 - Bank Mandiri - M";
      default:
        return "1111.001 - Kas Kecil - M";
    }
  }

  Future<PaymentResult> processPayment(PaymentData paymentData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sid = await prefs.getString('sid');
      // Construct payment data according to the API format
      final Map<String, dynamic> requestData = {
        "docstatus": 1,
        "naming_series": "ACC-SINV-.YYYY.-",
        "company": "Monroe",
        "cost_center": "Main - M",
        "posting_date": DateTime.now().toString().split(' ')[0],
        "posting_time":
            "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        "set_posting_time": 1,
        "is_pos": 1,
        "currency": "IDR",
        "conversion_rate": 1,
        "selling_price_list": "Standard Selling",
        "price_list_currency": "IDR",
        "base_net_total": paymentData.totalTagihan.toDouble(),
        "base_grand_total": paymentData.totalTagihan.toDouble(),
        "grand_total": paymentData.totalTagihan.toDouble(),
        "customer": "CUST-2024-01641", // Could be parameterized
        "pos_profile": "Monroe Pos",
        "payments": [
          {
            "mode_of_payment": paymentData.modeOfPayment == "Cash"
                ? "CASH"
                : paymentData.modeOfPayment,
            "amount": paymentData.modeOfPayment == "Cash"
                ? paymentData.cashAmount!.toDouble()
                : paymentData.totalTagihan.toDouble(),
            "base_amount": paymentData.totalTagihan.toDouble(),
            "reference_number": paymentData.modeOfPayment == "Cash"
                ? "-"
                : paymentData.referenceNumber,
            "account": getAccountForPaymentMethod(paymentData.modeOfPayment),
          }
        ],
        "items": paymentData.orders
            .map((order) => {
                  "item_code": order.itemCode,
                  "item_name": order.itemName,
                  "description": order.description,
                  "uom": order.uom,
                  "conversion_factor": order.conversionFactor,
                  "qty": order.qty,
                  "rate": order.rate,
                  "amount": order.amount,
                  "base_rate": order.baseRate,
                  "base_amount": order.baseAmount,
                  "price_list_rate": order.priceListRate,
                  "cost_center": "Main - M"
                })
            .toList(),
        "update_stock": 0,
        "debit_to": ""
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/resource/Sales%20Invoice'),
        headers: {
          'Cookie': 'sid=$sid',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentResult(
          success: true,
          message: 'Pembayaran berhasil diproses!',
          data: json.decode(response.body),
        );
      } else {
        return PaymentResult(
          success: false,
          message:
              'Terjadi kesalahan saat memproses pembayaran.\nKode: ${response.statusCode}\nPesan: ${response.body}',
          data: response.body,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}
