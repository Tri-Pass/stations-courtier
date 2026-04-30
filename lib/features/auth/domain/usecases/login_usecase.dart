import '../entities/driver_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<DriverEntity> call(String phone, String password) =>
      repository.login(phone, password);
}
