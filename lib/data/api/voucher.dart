import 'dart:convert';
import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String apiUrl = '${dotenv.env['API_URL']}/api/resource/Voucher';
String customApiUrl =
    '${dotenv.env['API_URL']}${dotenv.env['CUSTOM_VOUCHER_API']}.testCalculateDiscount';

Future<Map<String, dynamic>?> getVoucher(
  int limit,
  int start,
  String filter,
) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': '[["Voucher","docstatus","=","1"]]',
    });

    final http.Response response = await http.get(
      url,
      headers: {
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Jika berhasil, parsing JSON ke Map
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<Map<String, dynamic>?> getVoucherById(String voucher) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString('sid');
    final Uri url = Uri.parse('$apiUrl/$voucher');
    final http.Response response = await http.get(url, headers: {
      'Cookie': 'sid=$sid',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      // Tangani kesalahan jika status code bukan 200
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<Map<String, dynamic>?> calculateVoucher(
    Map<String, dynamic> data) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString('sid');
    final Uri url = Uri.parse(customApiUrl);
    final http.Response response = await http.post(
      url,
      headers: {
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Jika berhasil, parsing JSON ke Map
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      // Tangani kesalahan jika status code bukan 200
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    }
  } catch (e) {
    return null;
  }
}
