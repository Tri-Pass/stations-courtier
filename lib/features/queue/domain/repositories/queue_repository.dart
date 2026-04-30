import 'package:courtier/features/queue/domain/entities/queue_entry.dart';

abstract class QueueRepository {
  Future<List<QueueEntry>> getQueue(String status, {String? driverPhone, String? lineId});
  Future<List<Line>> fetchLines();
  Future<NfcDriverInfo> lookupByNfc(String tagId);
  Future<void> enqueue(String driverId, String lineId);
  Future<DriverInfo> searchDriver(String phone);
  Future<void> sendOtp(String driverId);
  Future<void> validateOtp(String driverId, String otp, String nfcId);
}
