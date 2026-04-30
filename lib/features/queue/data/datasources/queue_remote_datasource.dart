import 'package:courtier/core/config/api_config.dart';
import 'package:courtier/core/network/api_client.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart';

class QueueRemoteDataSource {
  final ApiClient _client;
  QueueRemoteDataSource(this._client);

  Future<List<QueueEntry>> getQueue(String status, {String? driverPhone, String? lineId}) async {
    final data = await _client.get(ApiConfig.queueByStatus(status, driverPhone: driverPhone, lineId: lineId));
    return (data as List).map((e) => QueueEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NfcDriverInfo> lookupByNfc(String tagId) async {
    final data = await _client.get(ApiConfig.driverByNfc(tagId));
    return NfcDriverInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Line>> fetchLines() async {
    final data = await _client.get(ApiConfig.lines);
    return (data as List).map((e) => Line.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> enqueue(String driverId, String lineId) async {
    await _client.post(ApiConfig.queue, {'driverId': driverId, 'lineId': lineId});
  }

  Future<DriverInfo> searchDriver(String phone) async {
    final data = await _client.get(ApiConfig.driverByPhone(phone));
    return DriverInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> sendOtp(String driverId) async {
    await _client.post(ApiConfig.sendOtp, {'driverId': driverId});
  }

  Future<void> validateOtp(String driverId, String otp, String nfcId) async {
    await _client.post(ApiConfig.validateOtp, {
      'driverId': driverId,
      'otp': otp,
      'nfc_id': nfcId,
    });
  }
}
