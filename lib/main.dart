import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:courtier/core/di/injection.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/l10n/locale_notifier.dart';
import 'package:courtier/core/router/router.dart';
import 'package:courtier/core/services/sunmi_nfc_service.dart';
import 'package:courtier/core/storage/local_storage.dart';
import 'package:courtier/core/theme/app_font_sizes.dart';
import 'package:courtier/core/theme/app_theme.dart';
import 'package:courtier/features/auth/domain/repositories/auth_repository.dart';
import 'package:courtier/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await setupDependencies();

  String initialLocation = '/login';
  try {
    final isAuth = await sl<AuthRepository>().isAuthenticated();
    if (isAuth) initialLocation = '/home';
  } catch (_) {
    await sl<LocalStorage>().clear();
  }

  runApp(TaxiDriverApp(initialLocation: initialLocation));
}

class TaxiDriverApp extends StatefulWidget {
  final String initialLocation;
  const TaxiDriverApp({super.key, required this.initialLocation});

  @override
  State<TaxiDriverApp> createState() => _TaxiDriverAppState();
}

class _TaxiDriverAppState extends State<TaxiDriverApp> {
  late final GoRouter _router;
  StreamSubscription<Map<String, dynamic>>? _nfcSub;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.initialLocation);
    Future.microtask(() async {
      await WakelockPlus.enable();
    });

    // When the app restarts already authenticated, restore auth state so the
    // socket connects and the courtier profile is loaded into the BLoC.
    if (widget.initialLocation == '/home') {
      Future.microtask(() => sl<AuthBloc>().add(AuthCheckEvent()));
    }
  }

  void _startNfc() {
    if (_nfcSub != null) return; // already running
    SunmiNfcService.ensureInitialized();
    SunmiNfcService.startScanning();
    _nfcSub = SunmiNfcService.allEventsStream().listen((event) {
      if (event['event'] == 'CARD_FOUND') {
        final tagId = event['details']?.toString() ?? '';
        if (tagId.isNotEmpty) {
          // /link-nfc page manages NFC itself — don't redirect
          final loc = _router.routerDelegate.currentConfiguration.uri.toString();
          if (!loc.startsWith('/link-nfc')) {
            _router.push('/nfc-confirm', extra: tagId);
          }
        }
      }
    });
  }

  void _stopNfc() {
    _nfcSub?.cancel();
    _nfcSub = null;
    SunmiNfcService.stopScanning();
  }

  @override
  void dispose() {
    _stopNfc();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            _stopNfc();
            _router.go('/login');
          } else if (state is AuthAuthenticated) {
            _startNfc();
            _router.go('/home');
          }
        },
        child: ValueListenableBuilder<Locale>(
          valueListenable: sl<LocaleNotifier>(),
          builder: (_, locale, __) => MaterialApp.router(
            title: 'wetaxi.courtier',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(AppFontSizes.scale),
              ),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}
