import 'package:courtier/core/env.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => Env.baseApiUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login  = '/auth/login';
  static const String me     = '/auth/me';

  // ── Queue ─────────────────────────────────────────────────────────────────
  static const String queue  = '/queue';
  static const String lines  = '/lines';

  static String queueByStatus(String status, {String? driverPhone, String? lineId}) {
    final sb = StringBuffer('/queue?status=$status');
    if (driverPhone != null && driverPhone.isNotEmpty) sb.write('&driverPhone=$driverPhone');
    if (lineId != null && lineId.isNotEmpty) sb.write('&lineId=$lineId');
    return sb.toString();
  }

  // ── NFC / Drivers ─────────────────────────────────────────────────────────
  static String driverByNfc(String tagId) => '/drivers/nfc?tagId=$tagId';
  static String driverByPhone(String phone) => '/driver?phone=$phone';
  static const String sendOtp     = '/driver/send-otp';
  static const String validateOtp = '/driver/validate-otp';

  // ── Socket channels ───────────────────────────────────────────────────────
  // Events: taxi_queued | taxi_departed | taxi_line_changed
  static String stationChannel(String stationId) => 'station/$stationId';
}
