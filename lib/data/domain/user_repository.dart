import 'package:pos/data/domain/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> login(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
