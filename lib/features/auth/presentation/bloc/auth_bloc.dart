import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:courtier/core/env.dart';
import 'package:courtier/core/network/api_client.dart';
import 'package:courtier/core/network/socket_service.dart';
import 'package:courtier/features/auth/domain/entities/driver_entity.dart';
import 'package:courtier/features/auth/domain/repositories/auth_repository.dart';
import 'package:courtier/features/auth/domain/usecases/login_usecase.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckEvent extends AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String phone;
  final String password;
  AuthLoginEvent(this.phone, this.password);
  @override
  List<Object?> get props => [phone, password];
}

class AuthLogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final DriverEntity driver;
  AuthAuthenticated(this.driver);
  @override
  List<Object?> get props => [driver];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;
  final SocketService _socketService;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
    required SocketService socketService,
  })  : _loginUseCase = loginUseCase,
        _authRepository = authRepository,
        _socketService = socketService,
        super(AuthInitial()) {
    on<AuthCheckEvent>(_onCheck);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckEvent event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) return;

    emit(AuthLoading());
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (!isAuth) {
        emit(AuthUnauthenticated());
        return;
      }
      final driver = await _authRepository.getProfile();
      _connectSocket();
      emit(AuthAuthenticated(driver));
    } catch (_) {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _loginUseCase(event.phone, event.password);
      final driver = await _authRepository.getProfile();
      _connectSocket();
      emit(AuthAuthenticated(driver));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Erreur de connexion au serveur'));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    _socketService.destroy();
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _connectSocket() async {
    if (_socketService.status == SocketConnectionStatus.connected ||
        _socketService.status == SocketConnectionStatus.connecting) return;
    final token = await _authRepository.getToken();
    if (token == null) return;
    _socketService.connect(SocketServiceOptions(
      url: Env.socketCluster,
      authToken: token,
    ));
  }
}
