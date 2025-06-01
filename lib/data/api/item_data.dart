import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String apiUrl =
    '${dotenv.env['API_URL']}${dotenv.env['CUSTOM_API']}.get_custom_items';

Future<Map<String, dynamic>?> getItemData(
    int limit,
    int start,
    String filter,
    bool searchByCode,
    String warehouse,
    bool allowStock,
    String priceListGroup) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sid = await prefs.getString('sid');

    final Map<String, String> params = {
      'price_list': priceListGroup,
      'fields':
          '["name","idx","item_code","item_name","item_group","stock_uom","disabled","is_stock_item","image","description"]',
      'limit_page_length': limit.toString(),
      'limit_start': start.toString(),
      'filters': searchByCode
          ? '[["Item","name","like","%${filter}%"]]'
          : '[["Item","item_name","like","%${filter}%"]]',
    };

// Tambahkan kondisi ini hanya jika showSoldItems == true
    if (allowStock) {
      params["with_stock"] = "1";
      params["warehouse"] = warehouse;
    }

    final Uri url = Uri.parse(apiUrl).replace(queryParameters: params);

    final http.Response response = await http.get(
      url,
      headers: {
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['message']['data'];

      return {
        'data': items,
      };
    } else {
      print('Error: ${response.body}');
      return null;
    }
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
