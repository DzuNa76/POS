import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String apiUrl = '${dotenv.env['API_URL']}/api/resource/Customer';

Future<Map<String, dynamic>?> getCustomerData(
    int limit, int start, String filter, bool searchByPhone) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    // Request data yang dikirim sebagai query parameter
    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': searchByPhone
          ? '[["Customer","custom_phone","like","%${filter}%"]]'
          : '[["Customer","customer_name","like","%${filter}%"]]'
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
      // Tangani kesalahan jika status code bukan 200
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      print('Error: $errorData');
      return null;
    }
  } catch (error) {
    print('Exception: $error');
    return null;
  }
}

Future<Map<String, dynamic>?> addNewCustomer(String token, String address,
    String phone, String email, String? socmed, String name) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    // Data yang dikirim ke ERPNext
    final Map<String, dynamic> requestData = {
      "customer_name": name,
      "customer_type": "Individual",
      "customer_group": "Individual",
      "territory": "Indonesia",
      "email_id": email,
      "mobile_no": phone,
      "custom_address": address,
      "custom_phone": phone,
      "custom_email": email,
      "custom_whatsapp": phone,
      "custom_sosmed": socmed
    };

    // Kirim request untuk membuat Customer di ERPNext
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Cookie': 'sid=$sid',
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      // Jika berhasil, parsing JSON ke Map
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      // Tangani kesalahan jika status code bukan 200
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      return errorData;
    }
  } catch (error) {
    print("Exception: $error");
    return {"error": "Exception occurred", "message": error.toString()};
  }
}
