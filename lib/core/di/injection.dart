import 'package:get_it/get_it.dart';
import 'package:courtier/core/l10n/locale_notifier.dart';
import 'package:courtier/core/network/api_client.dart';
import 'package:courtier/core/network/socket_service.dart';
import 'package:courtier/core/storage/local_storage.dart';
import 'package:courtier/core/theme/theme_notifier.dart';
import 'package:courtier/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:courtier/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:courtier/features/auth/domain/repositories/auth_repository.dart';
import 'package:courtier/features/auth/domain/usecases/login_usecase.dart';
import 'package:courtier/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:courtier/features/queue/data/datasources/queue_remote_datasource.dart';
import 'package:courtier/features/queue/data/repositories/queue_repository_impl.dart';
import 'package:courtier/features/queue/domain/repositories/queue_repository.dart';
import 'package:courtier/features/queue/presentation/bloc/queue_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Locale
  final localeNotifier = LocaleNotifier();
  await localeNotifier.init();
  sl.registerSingleton(localeNotifier);

  // Theme
  final themeNotifier = ThemeNotifier();
  await themeNotifier.init();
  sl.registerSingleton(themeNotifier);

  // Core infrastructure
  sl.registerLazySingleton(() => LocalStorage());
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => SocketService.getInstance());

  // Auth feature
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(
    () => AuthBloc(loginUseCase: sl(), authRepository: sl(), socketService: sl()),
  );

  // Queue feature
  sl.registerLazySingleton(() => QueueRemoteDataSource(sl()));
  sl.registerLazySingleton<QueueRepository>(() => QueueRepositoryImpl(sl()));
  sl.registerFactory(() => QueueBloc(sl(), sl(), sl()));
}
