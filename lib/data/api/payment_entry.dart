import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentReference {
  final String salesInvoice;
  final double amount;

  const PaymentReference({
    required this.salesInvoice,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'reference_doctype': 'Sales Invoice',
        'reference_name': salesInvoice,
        'allocated_amount': amount,
      };
}

// Singleton to cache and reuse shared preferences and sid
class AuthCache {
  static final AuthCache _instance = AuthCache._internal();
  factory AuthCache() => _instance;
  AuthCache._internal();

  SharedPreferences? _prefs;
  String? _sid;
  String? _apiUrl;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _sid ??= _prefs!.getString('sid');
    _apiUrl ??= dotenv.env['API_URL'];

    if (_sid == null) {
      throw Exception('Error: SID tidak ditemukan');
    }
  }

  String get sid => _sid!;
  String get apiUrl => _apiUrl!;

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        'Cookie': 'sid=$sid',
      };
}

Future<Map<String, dynamic>> createPaymentEntry({
  required String paymentType,
  required String modeOfPayment,
  required String party,
  required String partyType,
  required double paidAmount,
  required List<PaymentReference> references,
  required String kasbonAccount,
}) async {
  try {
    final authCache = AuthCache();
    await authCache.initialize();

    final Map<String, dynamic> payload = {
      "doctype": "Payment Entry",
      "payment_type": paymentType,
      "mode_of_payment": modeOfPayment,
      "party_type": partyType,
      "party": party,
      "paid_amount": paidAmount,
      "received_amount": paidAmount,
      "target_exchange_rate": 1.0,
      "paid_to": kasbonAccount,
      "paid_to_account_currency": "IDR",
      "reference_no": DateTime.now().millisecondsSinceEpoch.toString(),
      "reference_date": DateTime.now().toIso8601String().split('T')[0],
      "references": references.map((ref) => ref.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse("${authCache.apiUrl}/api/resource/Payment Entry"),
      headers: authCache.headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      // Process creation and submission in parallel
      final String docName = responseData['data']['name'];

      // Use a smaller delay if necessary
      await Future.delayed(const Duration(milliseconds: 200));

      // Get latest document and submit in parallel
      final latestDocFuture = getLatestPaymentEntryDocument(docName);
      final latestDoc = await latestDocFuture;
      await submitPaymentEntry(docName, latestDoc);

      return responseData;
    } else {
      throw Exception('Failed to create Payment Entry: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error creating Payment Entry: $e');
  }
}

Future<Map<String, dynamic>> getLatestPaymentEntryDocument(
    String docName) async {
  try {
    final authCache = AuthCache();
    await authCache.initialize();

    final response = await http.get(
      Uri.parse("${authCache.apiUrl}/api/resource/Payment Entry/$docName"),
      headers: authCache.headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get latest document: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error getting latest document: $e');
  }
}

Future<void> submitPaymentEntry(
    String docName, Map<String, dynamic> latestDoc) async {
  try {
    final authCache = AuthCache();
    await authCache.initialize();

    final Map<String, dynamic> payload = {
      "doctype": "Payment Entry",
      "name": docName,
      "cmd": "frappe.client.submit",
      "doc": latestDoc['data'],
    };

    final response = await http.post(
      Uri.parse("${authCache.apiUrl}/api/resource/Payment Entry/$docName"),
      headers: authCache.headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit Payment Entry: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error submitting Payment Entry: $e');
  }
}
