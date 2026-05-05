import 'package:courtier/core/env.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => Env.baseApiUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login  = '/api/courtier/auth/login';
  static const String me     = '/api/courtier/auth/me';

  // ── Queue ─────────────────────────────────────────────────────────────────
  static const String queue  = '/api/courtier/queue';
  static const String lines  = '/api/courtier/lines';

  static String queueByStatus(String status, {String? driverPhone, String? lineId}) {
    final sb = StringBuffer('/api/courtier/queue?status=$status');
    if (driverPhone != null && driverPhone.isNotEmpty) sb.write('&driverPhone=$driverPhone');
    if (lineId != null && lineId.isNotEmpty) sb.write('&lineId=$lineId');
    return sb.toString();
  }

  // ── NFC / Drivers ─────────────────────────────────────────────────────────
  static String driverByNfc(String tagId) => '/api/courtier/drivers/nfc?tagId=$tagId';
  static String driverByPhone(String phone) => '/api/courtier/driver?phone=$phone';
  static const String sendOtp     = '/api/courtier/driver/send-otp';
  static const String validateOtp = '/api/courtier/driver/validate-otp';

  // ── Socket channels ───────────────────────────────────────────────────────
  // Events: taxi_queued | taxi_departed | taxi_line_changed
  static String stationChannel(String stationId) => 'station/$stationId';
}
