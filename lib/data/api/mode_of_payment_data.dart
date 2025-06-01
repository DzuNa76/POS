import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pos/core/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

String apiURLALL = '${dotenv.env['API_URL']}/api/resource/POS%20Profile';

Future<Map<String, dynamic>?> getAllModeOfPayment() async {
  try {
    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    final Uri url = Uri.parse(apiURLALL);
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
  } catch (e) {
    print(e);
    return null;
  }
}

Future<Map<String, dynamic>?> getModeOfPayment(
    int limit, int start, String filter) async {
  try {
    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    String? selectedOutlet = await prefs.getString('selected_outlet');
    String apiUrl = '';

    if (ConfigService.isUsingOutlet) {
      apiUrl =
          '${dotenv.env['API_URL']}/api/resource/POS%20Profile/$selectedOutlet';
    } else {
      apiUrl = '${dotenv.env['API_URL']}/api/resource/POS%20Profile/Monroe Pos';
    }

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: {
      'fields': '["*"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      // 'filters': '[["name", "=", "Monroe Pos"]]'
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

Future<Map<String, dynamic>?> getModeOfPaymentPerItem(String id) async {
  try {
    String apiUrls =
        '${dotenv.env['API_URL']}/api/resource/Mode of Payment/$id';

    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');

    final Uri url = Uri.parse(apiUrls).replace(queryParameters: {
      'fields': '["*"]',
      'filters': '[["Mode of Payment","enabled","=","1"]]'
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

Future<Map<String, dynamic>?> getCompanyAddress(String id) async {
  try {
    String apiUrls = '${dotenv.env['API_URL']}/api/resource/Address/$id';

    // Ambil SID dari Hive
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');
    final Uri url = Uri.parse(apiUrls).replace(queryParameters: {
      'fields': '["*"]',
      'filters': '[["Address","enabled","=","1"]]'
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
  } catch (e) {
    return null;
  }
}
