import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Connection state machine ──────────────────────────────────────────────────
enum SocketConnectionStatus { idle, connecting, connected, reconnecting, dead }

// ─── Channel handler type ──────────────────────────────────────────────────────
enum SocketHandlerType {
  /// Server pushes a full payload — use it directly.
  data,
  /// Server fires a signal only — ignore payload, call the API instead.
  fetch,
}

// ─── Channel config ────────────────────────────────────────────────────────────
class SocketChannelConfig {
  final String channel;
  final SocketHandlerType handlerType;
  final void Function(dynamic data)? onData;
  final Future<void> Function()? onFetch;
  final String? owner;

  const SocketChannelConfig({
    required this.channel,
    required this.handlerType,
    this.onData,
    this.onFetch,
    this.owner,
  });
}

// ─── Reconnect options ─────────────────────────────────────────────────────────
class ReconnectOptions {
  final Duration interval;
  final Duration maxInterval;
  final int maxAttempts;

  const ReconnectOptions({
    this.interval    = const Duration(seconds: 3),
    this.maxInterval = const Duration(seconds: 30),
    this.maxAttempts = 20,
  });
}

// ─── Init options ──────────────────────────────────────────────────────────────
class SocketServiceOptions {
  final String url;
  String? authToken;
  final ReconnectOptions reconnect;
  final void Function(bool isAuthenticated, String? socketId)? onAuthResult;
  final void Function()? onMaxReconnectsReached;

  SocketServiceOptions({
    required this.url,
    this.authToken,
    this.reconnect       = const ReconnectOptions(),
    this.onAuthResult,
    this.onMaxReconnectsReached,
  });
}

// ─── Internals ─────────────────────────────────────────────────────────────────
const _kHeartbeatTimeout = Duration(minutes: 11);

// ─── Logger ───────────────────────────────────────────────────────────────────
void _log(String msg) => debugPrint('[Socket] $msg');

class SocketService with WidgetsBindingObserver {

  // ── Singleton ────────────────────────────────────────────────────────────
  static SocketService? _instance;
  static SocketService getInstance() => _instance ??= SocketService._();
  SocketService._();

  // ── Core ─────────────────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  SocketServiceOptions? _options;
  int _cid = 0;

  // ── State machine ─────────────────────────────────────────────────────────
  SocketConnectionStatus _status = SocketConnectionStatus.idle;
  final _statusController = StreamController<SocketConnectionStatus>.broadcast();

  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;
  SocketConnectionStatus get status => _status;
  bool get isConnected => _status == SocketConnectionStatus.connected;

  // ── Channels ──────────────────────────────────────────────────────────────
  final _channels    = <String, SocketChannelConfig>{};
  final _activeChans = <String>{};

  // ── Queue ─────────────────────────────────────────────────────────────────
  final _queue = <Map<String, dynamic>>[];

  // ── Reconnect ─────────────────────────────────────────────────────────────
  int    _attempts  = 0;
  bool   _destroyed = false;
  Timer? _reconnectTimer;

  // ── App lifecycle ─────────────────────────────────────────────────────────
  bool _inBackground = false;

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _heartbeatTimer;
  Timer? _handshakeTimer;
  int?   _pendingHandshakeCid;

  // ═════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═════════════════════════════════════════════════════════════════════════

  void connect(SocketServiceOptions options) {
    _log('🚀 connect() — url=${options.url} token=${options.authToken != null ? "present" : "NULL"}');
    WidgetsBinding.instance.removeObserver(this);
    _options   = options;
    _destroyed = false;
    _attempts  = 0;
    WidgetsBinding.instance.addObserver(this);
    _openSocket();
  }

  void updateToken(String token) {
    _log('🔑 token updated');
    _options?.authToken = token;
  }

  void subscribe(SocketChannelConfig config) {
    _log('📋 subscribe("${config.channel}") owner=${config.owner ?? "global"} type=${config.handlerType.name}');
    _channels[config.channel] = config;
    if (isConnected) _sendSubscribe(config.channel);
  }

  void subscribeAll(List<SocketChannelConfig> configs) {
    _log('📋 subscribeAll(${configs.length} channels): ${configs.map((c) => c.channel).toList()}');
    for (final c in configs) {
      subscribe(c);
    }
  }

  void unsubscribe(String channel) {
    _log('🔕 unsubscribe("$channel")');
    _channels.remove(channel);
    _activeChans.remove(channel);
    if (isConnected) _sendUnsubscribe(channel);
  }

  void unsubscribeByOwner(String owner) {
    final toRemove = _channels.entries
        .where((e) => e.value.owner == owner)
        .map((e) => e.key)
        .toList();
    _log('🧹 unsubscribeByOwner("$owner") — removing ${toRemove.length} channels: $toRemove');
    for (final ch in toRemove) {
      unsubscribe(ch);
    }
  }

  void unsubscribeAll() {
    _log('🧹 unsubscribeAll() — ${_activeChans.length} active channels');
    for (final ch in List.of(_activeChans)) {
      if (isConnected) _sendUnsubscribe(ch);
    }
    _channels.clear();
    _activeChans.clear();
  }

  void emit(String event, dynamic data) {
    final cid = ++_cid;
    final msg = <String, dynamic>{'event': event, 'data': data, 'cid': cid};
    if (isConnected) {
      _log('📤 emit — event="$event" cid=$cid data=$data');
      _rawSend(msg);
    } else {
      _log('📦 queued (not connected) — event="$event" cid=$cid');
      _queue.add(msg);
    }
  }

  void disconnect() {
    _log('🔌 disconnect()');
    _destroyed = true;
    _clearReconnectTimer();
    _clearHeartbeat();
    _clearHandshakeTimer();
    _pendingHandshakeCid = null;
    _activeChans.clear();
    _ws?.sink.close();
    _ws = null;
    WidgetsBinding.instance.removeObserver(this);
    _setStatus(SocketConnectionStatus.idle);
  }

  void destroy() {
    _log('💥 destroy()');
    disconnect();
    _channels.clear();
    _queue.clear();
    _cid      = 0;
    _attempts = 0;
  }

  void dispose() {
    destroy();
    _statusController.close();
  }

  void forceReconnect() {
    _log('🔁 forceReconnect()');
    if (_status == SocketConnectionStatus.dead ||
        _status == SocketConnectionStatus.idle) {
      _destroyed = false;
      _attempts  = 0;
      _setStatus(SocketConnectionStatus.reconnecting);
      _openSocket();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // APP LIFECYCLE
  // ═════════════════════════════════════════════════════════════════════════

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('📱 lifecycle → ${state.name}');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _inBackground = true;
        _clearReconnectTimer();
        _clearHeartbeat();

      case AppLifecycleState.resumed:
        _inBackground = false;
        if (!_destroyed) {
          if (isConnected) {
            _log('📱 resumed — already connected');
            _resetHeartbeat();
          } else {
            _log('📱 resumed — not connected, reconnecting immediately');
            _clearReconnectTimer();
            _attempts = 0;
            _openSocket();
          }
        }

      default:
        break;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SOCKET LIFECYCLE
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _openSocket() async {
    if (_options == null) return;

    _log('🔌 _openSocket() — url=${_options!.url} attempt=$_attempts status=${_status.name}');

    _ws?.sink.close();
    _ws = null;

    if (_status != SocketConnectionStatus.reconnecting) {
      _setStatus(SocketConnectionStatus.connecting);
    }

    try {
      _ws = WebSocketChannel.connect(Uri.parse(_options!.url));
      await _ws!.ready;
      _log('✅ TCP open — waiting for handshake ACK');

      _ws!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: (err) {
          _log('❌ stream error: $err');
          _onDone();
        },
        cancelOnError: false,
      );

      final handshakeCid = ++_cid;
      _pendingHandshakeCid = handshakeCid;

      _log('🤝 sending #handshake — cid=$handshakeCid token=${_options!.authToken != null ? "present" : "NULL"}');
      _rawSend({
        'event': '#handshake',
        'data' : {'authToken': _options!.authToken},
        'cid'  : handshakeCid,
      });

      _resetHeartbeat();

      _clearHandshakeTimer();
      _handshakeTimer = Timer(const Duration(seconds: 10), () {
        if (!isConnected) {
          _log('⏰ handshake timeout (10s) — forcing close');
          _ws?.sink.close();
        }
      });
    } catch (err) {
      _log('❌ _openSocket failed: $err');
      _ws = null;
      _scheduleReconnect();
    }
  }

  void _onDone() {
    _log('🔴 WebSocket closed — status=${_status.name} attempts=$_attempts destroyed=$_destroyed');
    _clearHeartbeat();
    _activeChans.clear();

    if (!_destroyed) {
      _setStatus(SocketConnectionStatus.reconnecting);
      _scheduleReconnect();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MESSAGE PARSER
  // ═════════════════════════════════════════════════════════════════════════

  void _onMessage(dynamic raw) {
    // ── Server ping: empty frame or #1 → echo back immediately ────────────
    // The server sends either an empty string or "#1" as its keepalive ping.
    // We ONLY echo it back — we never initiate our own pings.
    // Sending our own #1 alongside the server's #1 causes a collision that
    // makes the server close the connection.
    if (raw == null || raw == '' || raw == '#1') {
      _log('💓 server ping → ponging back');
      _ws?.sink.add(raw == '#1' ? '#1' : '');
      _resetHeartbeat();
      return;
    }

    // ── Server pong reply (if server ever sends #2) ────────────────────────
    if (raw == '#2') {
      _log('💓 server pong (#2) — connection alive ✅');
      _resetHeartbeat();
      return;
    }

    // Log every raw incoming frame (truncated to 500 chars)
    final preview = raw.toString().length > 500
        ? '${raw.toString().substring(0, 500)}…'
        : raw.toString();
    _log('📥 ← $preview');

    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      _log('⚠️ non-JSON frame, skipping: $e');
      return;
    }

    final event  = frame['event']  as String?;
    final data   = frame['data'];
    final rid    = frame['rid']    as int?;
    final cid    = frame['cid']    as int?;
    final action = frame['action'] as String?;

    // ── Custom action-based publish ────────────────────────────────────────
    if (action == 'publish') {
      final channel = frame['channel'] as String?;
      _log('📨 action=publish channel="$channel" data=$data');
      if (channel != null) _dispatchChannel(channel, data);
      return;
    }

    // ── Handshake ACK ──────────────────────────────────────────────────────
    if (event == null && rid != null && rid == _pendingHandshakeCid) {
      _clearHandshakeTimer();
      _pendingHandshakeCid = null;
      _attempts = 0;
      final p        = data as Map<String, dynamic>?;
      final isAuth   = p?['isAuthenticated'] as bool? ?? false;
      final socketId = p?['id'] as String?;
      _log('✅ handshake ACK — socketId=$socketId isAuthenticated=$isAuth');
      _options?.onAuthResult?.call(isAuth, socketId);
      _setStatus(SocketConnectionStatus.connected);
      _resubscribeAll();
      _flushQueue();
      return;
    }

    // ── Generic ACK ────────────────────────────────────────────────────────
    if (event == null && rid != null) {
      _log('✉️ ACK rid=$rid');
      _resetHeartbeat();
      return;
    }

    // ── Named events ──────────────────────────────────────────────────────
    switch (event) {
      case '#ping':
        _log('🏓 server #ping → #pong');
        _rawSend({'event': '#pong', 'data': {}, 'rid': cid});
        _resetHeartbeat();

      case '#publish':
        final pub     = data as Map<String, dynamic>?;
        final channel = pub?['channel'] as String?;
        _log('📨 #publish channel="$channel" data=${pub?['data']}');
        if (channel != null) _dispatchChannel(channel, pub?['data']);

      case '#setAuthToken':
        final token = (data as Map<String, dynamic>?)?['token'] as String?;
        _log('🔑 #setAuthToken token=${token != null ? "present" : "null"}');
        _options?.authToken = token;

      case '#removeAuthToken':
        _log('🔑 #removeAuthToken (SC auth cleared — keeping local JWT)');
    // Do NOT null _options?.authToken here.
    // Nulling it causes every reconnect to send authToken=null.

      default:
        if (event != null) {
          final cfg = _channels[event];
          if (cfg != null) {
            _log('📩 generic event="$event" → dispatching to handler');
            _dispatchToHandler(cfg, data);
          } else {
            _log('⚠️ generic event="$event" — no handler registered (known channels: ${_channels.keys.toList()})');
          }
          if (cid != null) {
            _log('✉️ sending ACK for cid=$cid');
            _rawSend({'rid': cid, 'error': null, 'data': null});
          }
        }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TYPE-BASED DISPATCH
  // ═════════════════════════════════════════════════════════════════════════

  void _dispatchChannel(String channel, dynamic data) {
    final cfg = _channels[channel];
    if (cfg == null) {
      _log('⚠️ no handler for channel="$channel" (registered: ${_channels.keys.toList()})');
      return;
    }
    _log('⚡ dispatching channel="$channel" type=${cfg.handlerType.name}');
    _dispatchToHandler(cfg, data);
  }

  void _dispatchToHandler(SocketChannelConfig cfg, dynamic data) {
    try {
      if (cfg.handlerType == SocketHandlerType.data) {
        _log('📦 DATA → channel="${cfg.channel}" data=$data');
        cfg.onData?.call(data);
      } else {
        _log('🔄 FETCH → channel="${cfg.channel}" (payload ignored, triggering API)');
        cfg.onFetch?.call();
      }
    } catch (e) {
      _log('❌ handler threw on channel="${cfg.channel}": $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═════════════════════════════════════════════════════════════════════════

  void _resubscribeAll() {
    final pending = _channels.keys.where((ch) => !_activeChans.contains(ch)).toList();
    _log('📡 resubscribeAll() — ${pending.length} channels: $pending');
    for (final ch in pending) {
      _sendSubscribe(ch);
    }
  }

  void _sendSubscribe(String channel) {
    _log('📤 → #subscribe channel="$channel"');
    _rawSend({
      'event': '#subscribe',
      'data' : {'channel': channel},
      'cid'  : ++_cid,
    });
    _activeChans.add(channel);
  }

  void _sendUnsubscribe(String channel) {
    _log('📤 → #unsubscribe channel="$channel"');
    _rawSend({
      'event': '#unsubscribe',
      'data' : channel,
      'cid'  : ++_cid,
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // OUTGOING QUEUE
  // ═════════════════════════════════════════════════════════════════════════

  void _flushQueue() {
    if (_queue.isEmpty) {
      _log('📦 queue empty — nothing to flush');
      return;
    }
    _log('📦 flushing ${_queue.length} queued messages');
    final pending = List.of(_queue);
    _queue.clear();
    for (final msg in pending) {
      _rawSend(msg);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RECONNECT
  // ═════════════════════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    if (_destroyed || _inBackground) {
      _log('⏸ reconnect skipped — destroyed=$_destroyed background=$_inBackground');
      return;
    }

    final opts = _options?.reconnect ?? const ReconnectOptions();

    if (_attempts >= opts.maxAttempts) {
      _log('💀 max attempts (${opts.maxAttempts}) reached — DEAD');
      _setStatus(SocketConnectionStatus.dead);
      _options?.onMaxReconnectsReached?.call();
      return;
    }

    final baseMs   = opts.interval.inMilliseconds * (1.5.pow(_attempts));
    final jitterMs = baseMs * 0.2 * (2 * _random() - 1);
    final delayMs  = (baseMs + jitterMs).clamp(0, opts.maxInterval.inMilliseconds);

    _log('⏳ reconnect in ${delayMs.round()}ms — attempt=${_attempts + 1}/${opts.maxAttempts}');

    _attempts++;
    _clearReconnectTimer();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs.round()), () {
      if (!_destroyed && !_inBackground) _openSocket();
    });
  }

  void _clearReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HEARTBEAT WATCHDOG
  // ═════════════════════════════════════════════════════════════════════════

  void _resetHeartbeat() {
    _clearHeartbeat();
    _heartbeatTimer = Timer(_kHeartbeatTimeout, () {
      _log('⚠️ heartbeat watchdog (${_kHeartbeatTimeout.inMinutes}min silence) — forcing close');
      _ws?.sink.close();
    });
  }

  void _clearHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _clearHandshakeTimer() {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  void _setStatus(SocketConnectionStatus next) {
    if (_status == next) return;
    _log('🔄 status: ${_status.name} → ${next.name}');
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  void _rawSend(Map<String, dynamic> msg) {
    try {
      final encoded = jsonEncode(msg);
      _log('📤 → $encoded');
      _ws?.sink.add(encoded);
    } catch (e) {
      _log('❌ send failed: $e');
    }
  }

  double _random() {
    return DateTime.now().microsecondsSinceEpoch % 1000 / 1000.0;
  }
}

// ─── Exported singleton ────────────────────────────────────────────────────────
final socketService = SocketService.getInstance();

// ─── Convenience extension ────────────────────────────────────────────────────
extension _NumPow on num {
  double pow(num exp) {
    double result = 1;
    for (var i = 0; i < exp; i++) {
      result *= this;
    }
    return result;
  }
}
