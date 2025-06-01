import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:shared_preferences/shared_preferences.dart';

String apiUrl = '${dotenv.env['API_URL']}/api/resource/Sales Invoice';

Future<Map<String, dynamic>?> getSalesInvoice(
    int limit,
    int start,
    String filter,
    String dateStart,
    String dateEnd,
    String modeOfPayment,
    String status,
    String returnAgainst) async {
  try {
    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    List<List<dynamic>> filters = [];

    filters.add([
      "Sales Invoice",
      "status",
      "not in",
      ["Overdue", "Draft", "Cancelled", "Unpaid", null]
    ]);

    if (filter.isNotEmpty) {
      filters.add(["Sales Invoice", "name", "like", "%$filter%"]);
    }

    if (dateStart.isNotEmpty && dateEnd.isNotEmpty) {
      filters.add([
        "Sales Invoice",
        "posting_date",
        "Between",
        [dateStart, dateEnd]
      ]);
    }

    if (modeOfPayment.isNotEmpty) {
      filters.add([
        "Sales Invoice",
        "custom_ui_mode_of_payment",
        "like",
        "%$modeOfPayment%"
      ]);
    }

    if (status.isNotEmpty) {
      filters.add(["Sales Invoice", "status", "like", "%$status%"]);
    }

    if (returnAgainst.isNotEmpty) {
      filters
          .add(["Sales Invoice", "return_against", "like", "%$returnAgainst%"]);
    }

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': jsonEncode(filters),
      'order_by': 'creation desc'
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

Future<Map<String, dynamic>?> getSalesInvoiceUnpaid(int limit, int start,
    String filter, String dateStart, String dateEnd, String customer) async {
  try {
    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    List<List<dynamic>> filters = [];

    filters.add([
      "Sales Invoice",
      "status",
      "not in",
      ["Paid", "Draft", "Return", "Submitted", "Cancelled", null]
    ]);

    if (customer.isNotEmpty) {
      filters.add(["Sales Invoice", "customer", "=", customer]);
    }

    if (filter.isNotEmpty) {
      filters.add(["Sales Invoice", "name", "like", "%$filter%"]);
    }

    if (dateStart.isNotEmpty && dateEnd.isNotEmpty) {
      filters.add([
        "Sales Invoice",
        "posting_date",
        "Between",
        [dateStart, dateEnd]
      ]);
    }

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': jsonEncode(filters),
      'order_by': 'creation desc'
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

Future<Map<String, dynamic>?> getSalesDraft(int limit, int start, String filter,
    String dateStart, String dateEnd) async {
  try {
    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    List<List<dynamic>> filters = [];

    filters.add(["Sales Invoice", "status", "=", "Draft"]);

    if (filter.isNotEmpty) {
      filters.add(["Sales Invoice", "name", "like", "%$filter%"]);
    }

    if (dateStart.isNotEmpty && dateEnd.isNotEmpty) {
      filters.add([
        "Sales Invoice",
        "posting_date",
        "Between",
        [dateStart, dateEnd]
      ]);
    }

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': jsonEncode(filters),
      'order_by': 'creation desc'
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

Future<dynamic> postSalesInvoice(
  Map<String, dynamic> payload,
) async {
  final String url = "${dotenv.env['API_URL']}/api/resource/Sales Invoice";
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? sid = await prefs.getString('sid');
  if (sid == null) {
    print('Error: JWT tidak ditemukan');
    return null;
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'status': 'success', 'message': response.body};
    } else {
      throw Exception('Failed to create Sales Invoice: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error posting Sales Invoice: $e');
  }
}

Future<Map<String, dynamic>> cancelSalesInvoice(String invoiceId) async {
  final String url = "${dotenv.env['API_URL']}/api/method/frappe.client.cancel";
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? sid = prefs.getString('sid');
  if (sid == null) {
    throw Exception('Error: JWT tidak ditemukan');
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  final Map<String, dynamic> payload = {
    "doctype": "Sales Invoice",
    "name": invoiceId,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Server error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print("Exception in cancelSalesInvoice: $e");
    rethrow;
  }
}

Future<Map<String, dynamic>> deleteSalesInvoice(String invoiceId) async {
  final String url =
      "${dotenv.env['API_URL']}/api/resource/Sales Invoice/$invoiceId";
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? sid = await prefs.getString('sid');
  if (sid == null) {
    throw Exception('Error: JWT tidak ditemukan');
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  try {
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    // Menerima status 200 OK DAN 202 Accepted sebagai sukses
    if (response.statusCode == 200 || response.statusCode == 202) {
      // Parse response JSON properly
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception(
          'Server error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print("Exception in API layer: $e");
    rethrow; // Simply rethrow to simplify error chain
  }
}

Future<Map<String, dynamic>> returnSalesInvoiceItem(
    {required String originalInvoiceId,
    required String itemCode,
    required String customer,
    required double qty,
    required double rate,
    required List<ModeOfPayments> modeOfPayment}) async {
  final String url = "${dotenv.env['API_URL']}/api/resource/Sales Invoice";
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String paymentMode = modeOfPayment[0].mode;

  String? sid = prefs.getString('sid');
  if (sid == null) {
    throw Exception('Error: SID tidak ditemukan');
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  // Calculate the total amount for the return (will be negative)
  double totalAmount = -qty * rate;

  final Map<String, dynamic> body = {
    "customer": customer,
    "is_return": 1,
    "return_against": originalInvoiceId,
    "docstatus": 0,
    "is_pos": 1,
    "items": [
      {"item_code": itemCode, "qty": -qty, "rate": rate, "amount": totalAmount}
    ],
    "write_off_amount": 0,
    "paid_amount": totalAmount,
    "payments": [
      {
        "mode_of_payment": paymentMode,
        "amount":
            totalAmount, // IMPORTANT: Use negative value to match the grand total
      }
    ],
  };

  print(jsonEncode(body));

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      log(response.body);
      final name = json.decode(response.body)['data']['name'];
      print(name);
      await submitSalesInvoice(name);

      return json.decode(response.body);
    } else {
      throw Exception(
        'Gagal melakukan return: ${response.statusCode} - ${response.body}',
      );
    }
  } catch (e) {
    print("Exception saat return item: $e");
    rethrow;
  }
}

Future<dynamic> submitSalesInvoice(String invoiceId) async {
  final String url =
      "${dotenv.env['API_URL']}/api/resource/Sales Invoice/$invoiceId?run_method=submit";
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? sid = await prefs.getString('sid');
  if (sid == null) {
    print('Error: JWT tidak ditemukan');
    return null;
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return 'success';
    } else {
      throw Exception('Failed to submit Sales Invoice: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error submitting Sales Invoice: $e');
  }
}

Future<dynamic> updateSalesInvoice(
    String invoiceId, Map<String, dynamic> payload) async {
  final String url =
      "${dotenv.env['API_URL']}/api/resource/Sales Invoice/$invoiceId";
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? sid = await prefs.getString('sid');
  if (sid == null) {
    print('Error: JWT tidak ditemukan');
    return null;
  }

  final Map<String, String> headers = {
    "Content-Type": "application/json",
    'Cookie': 'sid=$sid',
  };

  try {
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return 'success';
    } else {
      throw Exception('Failed to update Sales Invoice: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error updating Sales Invoice: $e');
  }
}
