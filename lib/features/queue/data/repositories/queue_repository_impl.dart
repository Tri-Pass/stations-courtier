import 'package:courtier/features/queue/data/datasources/queue_remote_datasource.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart';
import 'package:courtier/features/queue/domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDataSource _dataSource;
  QueueRepositoryImpl(this._dataSource);

  @override
  Future<List<QueueEntry>> getQueue(String status, {String? driverPhone, String? lineId}) =>
      _dataSource.getQueue(status, driverPhone: driverPhone, lineId: lineId);

  @override
  Future<List<Line>> fetchLines() => _dataSource.fetchLines();

  @override
  Future<NfcDriverInfo> lookupByNfc(String tagId) => _dataSource.lookupByNfc(tagId);

  @override
  Future<void> enqueue(String driverId, String lineId) => _dataSource.enqueue(driverId, lineId);

  @override
  Future<DriverInfo> searchDriver(String phone) => _dataSource.searchDriver(phone);

  @override
  Future<void> sendOtp(String driverId) => _dataSource.sendOtp(driverId);

  @override
  Future<void> validateOtp(String driverId, String otp, String nfcId) =>
      _dataSource.validateOtp(driverId, otp, nfcId);
}
