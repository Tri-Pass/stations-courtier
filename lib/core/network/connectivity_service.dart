import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityState { checking, online, offline }

class ConnectivityService {
  // Socket check confirms real internet access, not just an adapter being up.
  static const _host    = '8.8.8.8';
  static const _port    = 53;
  static const _timeout = Duration(seconds: 3);

  // Poll slowly while online (battery-friendly), quickly while offline so
  // the banner disappears as soon as WiFi comes back.
  static const _onlineInterval  = Duration(seconds: 15);
  static const _offlineInterval = Duration(seconds: 4);

  final _state = ValueNotifier<ConnectivityState>(ConnectivityState.checking);
  ValueNotifier<ConnectivityState> get state => _state;

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    await _check();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _timer?.cancel();
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      _state.value = ConnectivityState.offline;
      _scheduleNext();
    } else {
      // Adapter is up — verify actual internet with a socket probe.
      _check();
    }
  }

  Future<void> recheck() async {
    _timer?.cancel();
    await _check();
  }

  Future<void> _check() async {
    try {
      final socket = await Socket.connect(_host, _port, timeout: _timeout);
      socket.destroy();
      _state.value = ConnectivityState.online;
    } catch (_) {
      _state.value = ConnectivityState.offline;
    }
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final interval = _state.value == ConnectivityState.online
        ? _onlineInterval
        : _offlineInterval;
    _timer = Timer(interval, _check);
  }

  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    _state.dispose();
  }
}
