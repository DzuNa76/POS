import 'dart:convert';
import 'package:http/http.dart' as http;

class TestService {
  static const String baseUrl = 'https://monroe.my.id/api/resource';

  static const Map<String, String> headers = {
    'Cookie': 'full_name=Administrator; sid=9d4810b8a1282ce48c14a5dd8c12f60236518e02a7e67511cfd61da3; system_user=yes; user_id=Administrator; user_image='
  };

  // Ambil semua Sales Invoices
  static Future<List<dynamic>> fetchSalesInvoices() async {
    final url = Uri.parse('$baseUrl/Sales Invoice?fields=["*"]');
    final startTime = DateTime.now();
    print('Start fetching sales invoices at: $startTime');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final endTime = DateTime.now();
        print('Finished fetching sales invoices at: $endTime');
        print('Total duration: ${endTime.difference(startTime).inMilliseconds} ms');
        return data['data']; // Pastikan sesuai dengan struktur JSON response dari API
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      final endTime = DateTime.now();
      print('Error fetching sales invoices at: $endTime');
      print('Total duration (including error): ${endTime.difference(startTime).inMilliseconds} ms');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Ambil detail Sales Invoice berdasarkan ID
  static Future<Map<String, dynamic>> fetchInvoiceDetail(String invoiceId) async {
    final startTime = DateTime.now();
    print('Start fetching detail for invoice $invoiceId at: $startTime');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Sales Invoice/$invoiceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final endTime = DateTime.now();
        print('Finished fetching detail for invoice $invoiceId at: $endTime');
        print('Total duration: ${endTime.difference(startTime).inMilliseconds} ms');
        return json.decode(response.body)['data'];
      } else {
        throw Exception("Gagal mengambil detail invoice: ${response.statusCode}");
      }
    } catch (e) {
      final endTime = DateTime.now();
      print('Error fetching detail for invoice $invoiceId at: $endTime');
      print('Total duration (including error): ${endTime.difference(startTime).inMilliseconds} ms');
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
