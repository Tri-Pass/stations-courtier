import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = location.startsWith('/link-nfc') ? 1 : 0;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (i) {
            if (i == 0) {
              context.go('/home');
            } else {
              context.go('/link-nfc');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_rounded),
              label: l.navQueue,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.nfc_rounded),
              label: l.navLinkNfc,
            ),
          ],
        ),
      ),
    );
  }
}
