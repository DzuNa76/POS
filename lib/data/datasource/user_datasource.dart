import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos/data/models/user_model.dart';

abstract class UserDataSource {
  Future<UserModel?> login(String email, String password);
}

class UserDataSourceImpl implements UserDataSource {
  final http.Client client;
  final String baseUrl;

  UserDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<UserModel?> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
