import 'package:courtier/core/storage/local_storage.dart';
import 'package:courtier/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:courtier/features/auth/domain/entities/driver_entity.dart';
import 'package:courtier/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final LocalStorage _storage;

  AuthRepositoryImpl(this._dataSource, this._storage);

  @override
  Future<DriverEntity> login(String phone, String password) async {
    final data = await _dataSource.login(phone, password);
    final token = data['token'] as String;
    await _storage.saveToken(token);
    // Login response: { "token": "...", "courtier": { ... } }
    final courtier = _mapCourtier(data['courtier'] as Map<String, dynamic>);
    if (courtier.station != null) {
      await _storage.saveStationId(courtier.station!.id);
    }
    return courtier;
  }

  @override
  Future<DriverEntity> getProfile() async {
    // /api/courtier/auth/me returns the courtier object directly
    final data = await _dataSource.getProfile();
    return _mapCourtier(data);
  }

  @override
  Future<bool> isAuthenticated() => _storage.hasToken();

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<String?> getToken() => _storage.getToken();

  DriverEntity _mapCourtier(Map<String, dynamic> d) {
    StationEntity? station;
    if (d['station'] is Map<String, dynamic>) {
      final s = d['station'] as Map<String, dynamic>;
      station = StationEntity(
        id: (s['_id'] ?? s['id'] ?? '') as String,
        name: (s['name'] ?? '') as String,
        code: s['code'] as String?,
        city: s['city'] as String?,
      );
    }

    return DriverEntity(
      id: (d['_id'] ?? d['id'] ?? '') as String,
      name: (d['name'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      taxiNumber: '',
      plateNumber: '',
      balance: 0,
      station: station,
    );
  }
}
