import 'package:pos/data/api/customer_data.dart' as customer_data;
import 'package:pos/data/models/customer/customer.dart';

class CustomerActions {
  static Future<List<Customer>> getCustomers(
      int limit, int start, String filters,
      {bool searchByPhone = false}) async {
    try {
      final response = await customer_data.getCustomerData(
          limit, start, filters, searchByPhone);
      if (response == null || response['data'] == null) {
        return [];
      }
      final List<Customer> customers = response['data']
          .map<Customer>((json) => Customer.fromJson(json))
          .toList();
      return customers;
    } catch (e) {
      throw Exception('Error getting customers: $e');
    }
  }

  static Future<Map<String, dynamic>> addCustomer({
    required String token,
    required String address,
    required String phone,
    required String email,
    required String name,
    String? socmed,
  }) async {
    try {
      final response = await customer_data.addNewCustomer(
        token,
        address,
        phone,
        email,
        socmed,
        name,
      );

      if (response != null && response.containsKey('data')) {
        return response['data'];
      } else {
        return response!;
      }
    } catch (e) {
      throw Exception('Error adding customer: $e');
    }
  }

  static Future<List<Customer>> getAllCustomers(String filter) async {
    try {
      // Make initial request to get total count
      final firstBatch = await getCustomers(200, 0, '');
      final List<Customer> allCustomers = [...firstBatch];

      // If there are more customers, fetch them
      // int currentSkip = 200;
      // while (true) {
      //   final nextBatch = await getCustomers(currentSkip, 200, '');
      //   if (nextBatch.isEmpty) break;
      //   allCustomers.addAll(nextBatch);
      //   currentSkip += 200;
      // }

      return allCustomers;
    } catch (e) {
      throw Exception('Error getting alls customers: $e');
    }
  }
}
