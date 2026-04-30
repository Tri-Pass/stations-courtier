import 'package:go_router/go_router.dart';
import 'package:courtier/core/shell/main_shell.dart';
import 'package:courtier/features/auth/presentation/pages/login_page.dart';
import 'package:courtier/features/home/presentation/pages/home_page.dart';
import 'package:courtier/features/link_nfc/presentation/pages/link_nfc_page.dart';
import 'package:courtier/features/nfc/presentation/pages/nfc_confirm_page.dart';
import 'package:courtier/features/profile/presentation/pages/profile_page.dart';

GoRouter createRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (c, s) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (c, s) => const HomePage(),
            ),
            GoRoute(
              path: '/link-nfc',
              builder: (c, s) => const LinkNfcPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/nfc-confirm',
          builder: (c, s) => NfcConfirmPage(nfcTagId: s.extra as String),
        ),
        GoRoute(
          path: '/profile',
          builder: (c, s) => const ProfilePage(),
        ),
      ],
    );
