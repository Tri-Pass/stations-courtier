import 'package:courtier/core/config/api_config.dart';
import 'package:courtier/core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient _client;
  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    return await _client.post(
      ApiConfig.login,
      {'phone': phone, 'password': password},
      auth: false,
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await _client.get(ApiConfig.me);
  }
}
