import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_client.dart';

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  static String baseUrl = '${dotenv.env['API_URL']}/api/resource';

  // Fetch list of sales invoices using http with limit and offset
  static Future<List<Map<String, dynamic>>> getSalesInvoices(
      {int limit = 200,
      int offset = 0,
      String orderBy = 'posting_date desc', // Parameter pengurutan default
      String filterDateStart = '',
      String filterDateEnd = ''}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sid = await prefs.getString('sid');
      String apiUrl = '${dotenv.env['API_URL']}/api/resource/Item';

      final startTime = DateTime.now();
      final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
        'fields': '["*"]',
        'limit_page_length': limit.toString(),
        'limit_start': offset.toString(),
        'filters':
            ' [["Sales Invoice","from_date","Between",["${filterDateStart.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : filterDateStart}","${filterDateEnd.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : filterDateEnd}"]]'
      });

      final http.Response response = await http.get(
        url,
        headers: {
          'Cookie': 'sid=$sid',
          'Content-Type': 'application/json',
        },
      );
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        throw Exception(
            'Failed to load sales invoices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Fetch detail of a specific sales invoice using http
  static Future<Map<String, dynamic>> getSalesInvoiceDetail(
      String invoiceId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sid = await prefs.getString('sid');
      final response = await http.get(
        Uri.parse('$baseUrl/Sales Invoice/$invoiceId'),
        headers: {
          'Cookie': 'sid=$sid',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        throw Exception(
            'Failed to load invoice details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>?> getItemData(
      String token, int limit, int start, String filter) async {
    try {
      String apiUrl = '${dotenv.env['API_URL']}/api/resource/Item';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sid = await prefs.getString('sid');

      final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
        'fields': '["*"]',
        'limit_page_length': limit.toString(),
        'limit_start': start.toString(),
        'filters': '[["Item","item_name","like","%${filter}%"]]'
      });

      final http.Response response = await http.get(
        url,
        headers: {
          'Cookie': 'sid=$sid',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Error: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  // Fetch items using Dio
  Future<List<dynamic>> fetchItems(int limit, int offset) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sid = await prefs.getString('sid');
      final response = await _dioClient.dio.get(
        '/Item',
        queryParameters: {
          'fields': '["*"]',
          'limit_page_length': limit,
          'limit_start': offset,
        },
        options: Options(
          headers: {
            'Cookie': 'sid=$sid',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }

  // Convert API invoice data to app transaction format
  static Map<String, dynamic> convertToTransactionFormat(
      Map<String, dynamic> apiInvoice) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');

    // Determine payment method from payments array
    String paymentMethod = 'Lainnya';
    if (apiInvoice['payments'] != null && apiInvoice['payments'].isNotEmpty) {
      final payment = apiInvoice['payments'][0];
      final type = payment['type'] ?? '';

      if (type == 'Cash') {
        paymentMethod = 'Tunai';
      } else if (type == 'Bank') {
        paymentMethod = 'Debit';
      } else if (type == 'UPI' || type.contains('QR')) {
        paymentMethod = 'QRIS';
      }
    }

    // Get payment information from payment_schedule
    int paidAmount = 0;
    int outstandingAmount = 0;

    if (apiInvoice['payment_schedule'] != null &&
        apiInvoice['payment_schedule'].isNotEmpty) {
      final paymentSchedule = apiInvoice['payment_schedule'][0];
      paidAmount = paymentSchedule['paid_amount']?.toInt() ?? 0;
      outstandingAmount = paymentSchedule['outstanding']?.toInt() ?? 0;
    } else {
      // Fallback to old way if payment_schedule is not available
      paidAmount = apiInvoice['paid_amount']?.toInt() ??
          apiInvoice['grand_total']?.toInt() ??
          0;
    }

    return {
      'transactionId': apiInvoice['name'],
      'transactionDate':
          dateFormat.format(DateTime.parse(apiInvoice['posting_date'])),
      'customerName': apiInvoice['customer_name'] ?? 'Pelanggan',
      'paymentMethod': paymentMethod,
      'referralCode': apiInvoice['po_no'] ?? '',
      'cashierName': apiInvoice['owner']?.split('@')?.first ?? 'Admin',
      'subtotal': apiInvoice['net_total']?.toInt() ?? 0,
      'tax': (apiInvoice['total_taxes_and_charges'] ?? 0).toInt(),
      'total': apiInvoice['grand_total']?.toInt() ?? 0,
      'paid': paidAmount,
      'outstanding': outstandingAmount,
      'change': apiInvoice['change_amount']?.toInt() ?? 0,
    };
  }

  // Convert API invoice items to order items format
  static List<Map<String, dynamic>> convertToOrderItems(
      Map<String, dynamic> apiInvoice) {
    final List<dynamic> apiItems = apiInvoice['items'] ?? [];

    return apiItems.map<Map<String, dynamic>>((item) {
      return {
        'name': item['item_name'] ?? 'Unknown Item',
        'quantity': item['qty']?.toInt() ?? 0,
        'price': item['rate']?.toInt() ?? 0,
      };
    }).toList();
  }

  Future<int> fetchTotalItemsCount() async {
    try {
      int totalCount = 0;
      int batchSize = 500;
      int offset = 0;
      bool hasMoreData = true;

      while (hasMoreData) {
        final response = await _dioClient.dio.get(
          '/Item',
          queryParameters: {
            'fields': '["name"]',
            'limit_page_length': batchSize,
            'limit_start': offset,
          },
        );

        if (response.statusCode == 200) {
          List<dynamic> items = response.data['data'];
          totalCount += items.length;
          offset += batchSize;

          // Jika jumlah data yang diterima kurang dari batchSize, berarti sudah tidak ada data lagi
          if (items.length < batchSize) {
            hasMoreData = false;
          }
        } else {
          throw Exception('Failed to fetch items');
        }
      }

      return totalCount;
    } catch (e) {
      throw Exception('Error fetching total items count: $e');
    }
  }
}
