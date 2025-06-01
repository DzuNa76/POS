import 'package:pos/data/api/mode_of_payment_data.dart' as mode_of_payment;
import 'package:pos/data/models/mode_of_payment_models.dart';

class ModeOfPaymentAction {
  static Future<List<ModeOfPayment>> getModeOfPayment(
      int limit, int start, String filters) async {
    try {
      final response =
          await mode_of_payment.getModeOfPayment(limit, start, filters);

      if (response == null || response['data'] == null) {
        return [];
      }
      final List<dynamic> itemsJson = response['data']['payments'];
      return itemsJson.map((json) => ModeOfPayment.fromJson(json)).toList();
    } catch (error) {
      print('Error: $error');
      throw Exception('Error fetching items: $error');
    }
  }

  static Future<Map<String, dynamic>> getPosProfile() async {
    try {
      final response = await mode_of_payment.getModeOfPayment(1000, 0, '');
      if (response == null || response['data'] == null) {
        return {};
      }
      return response['data'];
    } catch (error) {
      print('Error: $error');
      throw Exception('Error fetching items: $error');
    }
  }

  static Future<String> getWarehouseName() async {
    try {
      final response = await mode_of_payment.getModeOfPayment(1000, 0, '');
      if (response == null || response['data'] == null) {
        return '';
      }
      return response['data']['warehouse'];
    } catch (error) {
      print('Error: $error');
      throw Exception('Error fetching items: $error');
    }
  }

  static Future<Map<String, dynamic>> getCompanyAddress(String id) async {
    try {
      final response = await mode_of_payment.getCompanyAddress(id);
      if (response == null || response['data'] == null) {
        return {};
      }
      return response['data'];
    } catch (error) {
      print('Error: $error');
      throw Exception('Error fetching items: $error');
    }
  }
}
