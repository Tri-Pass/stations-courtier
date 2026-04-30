import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

class SunmiNfcService {
  static const _methodChannel = MethodChannel('courtier/card_methods');
  static const _eventChannel = EventChannel('courtier/card_events');

  static final _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          _controller.add(Map<String, dynamic>.from(event));
        }
      },
      onError: (e) => log('NFC native stream error: $e'),
    );
  }

  static Future<void> startScanning() async {
    try {
      await _methodChannel.invokeMethod('startNfcScan');
    } on PlatformException catch (e) {
      log('NFC start error: ${e.message}');
    }
  }

  static Future<void> stopScanning() async {
    try {
      await _methodChannel.invokeMethod('stopNfcScan');
    } on PlatformException catch (e) {
      log('NFC stop error: ${e.message}');
    }
  }

  static Stream<Map<String, dynamic>> allEventsStream() => _controller.stream;

  static Stream<String> cardIdStream() {
    return _controller.stream
        .where((e) => e['event'] == 'CARD_FOUND')
        .map((e) => e['details']?.toString() ?? '');
  }

  static String toLittleEndianDecimal(String hex) {
    final bytes = <String>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(hex.substring(i, i + 2));
    }
    final reversedHex = bytes.reversed.join();
    return BigInt.parse(reversedHex, radix: 16).toString();
  }
}
