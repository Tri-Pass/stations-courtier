import '../entities/driver_entity.dart';

abstract class AuthRepository {
  Future<DriverEntity> login(String phone, String password);
  Future<DriverEntity> getProfile();
  Future<bool> isAuthenticated();
  Future<void> logout();
  Future<String?> getToken();
}
