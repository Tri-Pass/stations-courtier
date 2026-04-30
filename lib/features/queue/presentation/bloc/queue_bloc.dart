import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:courtier/core/network/api_client.dart';
import 'package:courtier/core/network/socket_service.dart';
import 'package:courtier/core/storage/local_storage.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart';
import 'package:courtier/features/queue/domain/repositories/queue_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class QueueEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class QueueLoad extends QueueEvent {}

class QueueRefresh extends QueueEvent {}

class QueueApplyFilter extends QueueEvent {
  final String? driverPhone;
  final String? lineId;

  QueueApplyFilter({this.driverPhone, this.lineId});

  @override
  List<Object?> get props => [driverPhone, lineId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class QueueState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {}

class QueueLoading extends QueueState {}

class QueueLoaded extends QueueState {
  // API-filtered lists (used as base for local filtering)
  final List<QueueEntry> waiting;
  final List<QueueEntry> active;
  final List<QueueEntry> completed;

  // Always the full unfiltered results — used by UI for local search & line dropdown
  final List<QueueEntry> allWaiting;
  final List<QueueEntry> allActive;
  final List<QueueEntry> allCompleted;

  // Lines fetched from /lines endpoint
  final List<Line> lines;

  QueueLoaded({
    required this.waiting,
    required this.active,
    required this.completed,
    List<QueueEntry>? allWaiting,
    List<QueueEntry>? allActive,
    List<QueueEntry>? allCompleted,
    this.lines = const [],
  })  : allWaiting   = allWaiting   ?? waiting,
        allActive    = allActive    ?? active,
        allCompleted = allCompleted ?? completed;

  @override
  List<Object?> get props => [
    waiting,
    active,
    completed,
    allWaiting,
    allActive,
    allCompleted,
    lines,
  ];
}

class QueueError extends QueueState {
  final String message;

  QueueError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

const _kSocketOwner = 'queue_bloc';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueRepository _repo;
  final SocketService _socket;
  final LocalStorage _storage;

  String? _filterPhone;
  String? _filterLineId;
  List<Line> _lines = [];

  QueueBloc(this._repo, this._socket, this._storage) : super(QueueInitial()) {
    on<QueueLoad>(_onLoad);
    on<QueueRefresh>(_onRefresh);
    on<QueueApplyFilter>(_onApplyFilter);
  }

  Future<void> _onLoad(QueueLoad event, Emitter<QueueState> emit) async {
    emit(QueueLoading());
    await _fetchAndEmit(emit);
    await _subscribeSocket();
  }

  Future<void> _onRefresh(QueueRefresh event, Emitter<QueueState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onApplyFilter(
      QueueApplyFilter event, Emitter<QueueState> emit) async {
    _filterPhone = event.driverPhone;
    _filterLineId = event.lineId;
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<QueueState> emit) async {
    try {
      final hasFilter = _filterPhone != null || _filterLineId != null;

      // Kick off lines fetch in parallel with queue fetch (only if not yet loaded)
      final linesFuture = _lines.isEmpty
          ? _repo.fetchLines().catchError((_) => <Line>[])
          : Future.value(_lines);

      final results = await Future.wait([
        _repo.getQueue('waiting',
            driverPhone: _filterPhone, lineId: _filterLineId),
        _repo.getQueue('active',
            driverPhone: _filterPhone, lineId: _filterLineId),
        _repo.getQueue('completed',
            driverPhone: _filterPhone, lineId: _filterLineId),
      ]);

      _lines = await linesFuture;

      List<QueueEntry> allWaiting, allActive, allCompleted;
      if (hasFilter) {
        final allResults = await Future.wait([
          _repo.getQueue('waiting'),
          _repo.getQueue('active'),
          _repo.getQueue('completed'),
        ]);
        allWaiting   = allResults[0];
        allActive    = allResults[1];
        allCompleted = allResults[2];
      } else {
        allWaiting   = results[0];
        allActive    = results[1];
        allCompleted = results[2];
      }

      emit(QueueLoaded(
        waiting:      results[0],
        active:       results[1],
        completed:    results[2],
        allWaiting:   allWaiting,
        allActive:    allActive,
        allCompleted: allCompleted,
        lines:        _lines,
      ));
    } on ApiException catch (e) {
      emit(QueueError(e.message));
    } catch (_) {
      emit(QueueError('Erreur de connexion'));
    }
  }

  Future<void> _subscribeSocket() async {
    final stationId = await _storage.getStationId();
    if (stationId == null || stationId.isEmpty) return;

    final channel = 'station/$stationId';

    final config = SocketChannelConfig(
      channel: channel,
      handlerType: SocketHandlerType.fetch,
      onFetch: () async => add(QueueRefresh()),
      owner: _kSocketOwner,
    );

    _socket.subscribe(config);
  }

  @override
  Future<void> close() {
    _socket.unsubscribeByOwner(_kSocketOwner);
    return super.close();
  }
}