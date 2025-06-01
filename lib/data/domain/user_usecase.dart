import 'package:pos/data/domain/user_repository.dart';
import 'package:pos/data/domain/user_entity.dart';
import 'package:pos/data/domain/usecase.dart';

class LoginUseCase extends UseCase<UserEntity?, LoginParams> {
  final UserRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<UserEntity?> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}

class LogoutUseCase extends UseCase<void, NoParams> {
  final UserRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.logout();
  }
}

class GetCurrentUserUseCase extends UseCase<UserEntity?, NoParams> {
  final UserRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<UserEntity?> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
