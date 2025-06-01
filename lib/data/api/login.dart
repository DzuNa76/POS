import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Gunakan dotenv untuk membaca URL API
  final String baseUrl = "${dotenv.env['API_URL']}/api/method/login";

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // Data yang akan dikirim ke server
      final Map<String, dynamic> data = {
        "usr": username,
        "pwd": password,
      };

      // Header yang diperlukan
      final Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      // Kirim request ke server
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        log(username.toString());

        // Ambil data dari respons API
        final String message = responseData["message"] ?? "No message";
        final String homePage = responseData["home_page"] ?? "/";
        final String fullName = responseData["full_name"] ?? "Anonymous";

        // Log hasil parsing
        print("Message: $message");
        print("Home Page: $homePage");
        print("Full Name: $fullName");

        final Map<String, dynamic> data = jsonDecode(response.body);
        String? cookie = response.headers['set-cookie'];
        if (cookie != null) {
          RegExp regex = RegExp(r'sid=([^;]+)');
          Match? match = regex.firstMatch(cookie);
          if (match != null) {
            String sid = match.group(1)!;
            print('Login berhasil. SID: $sid');

            final String url =
                "${dotenv.env['API_URL']}/api/resource/User/$username";
            final Map<String, String> headers = {
              "Content-Type": "application/json",
              'Cookie': 'sid=$sid',
            };

            final responseUser = await http.get(
              Uri.parse(url),
              headers: headers,
            );

            if (responseUser.statusCode == 200) {
              return {
                "message": message,
                "homePage": homePage,
                "fullName": fullName,
                "sid": sid,
                "role": responseUser.body
              };
            }
          }
        }
      } else {
        // Handle jika status code bukan 200
        print("Error: ${response.body}");
        return null;
      }
    } catch (e) {
      // Tangani error lain seperti jaringan atau parsing
      print("Exception: $e");
      return null;
    }
  }
}
