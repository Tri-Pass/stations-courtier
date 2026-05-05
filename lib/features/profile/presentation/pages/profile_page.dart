import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:courtier/core/di/injection.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/l10n/locale_notifier.dart';
import 'package:courtier/core/theme/app_theme.dart';
import 'package:courtier/core/theme/theme_notifier.dart';
import 'package:courtier/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final driver = state is AuthAuthenticated ? state.driver : null;
        final l = AppLocalizations.of(context);
        final c = context.appColors;
        final name = driver?.name ?? 'Courtier';
        final phone = driver?.phone ?? '—';
        final station = driver?.station?.name ?? '—';
        final agentId = driver?.id ?? 'CTR-001';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l.profile,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: c.textPrimary, size: 18),
              onPressed: () => context.go('/home'),
            ),
          ),
          backgroundColor: c.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),

                // ── Profile card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5A300), Color(0xFFE08800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.badge_outlined, color: Colors.black87, size: 44),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.courtierRole,
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Information ───────────────────────────────────────────
                Text(
                  l.information,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                _InfoRow(icon: Icons.phone, label: l.phone, value: phone),
                _InfoRow(icon: Icons.location_on, label: l.stationLabel, value: station),
                _InfoRow(icon: Icons.badge, label: l.agentId, value: agentId),
                const SizedBox(height: 28),

                // ── Appearance / Theme ────────────────────────────────────
                Text(
                  l.theme,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                const _ThemeSelector(),
                const SizedBox(height: 28),

                // ── Language ──────────────────────────────────────────────
                Text(
                  l.language,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                const _LanguageSelector(),
                const SizedBox(height: 28),

                // ── Logout ────────────────────────────────────────────────
                _ActionButton(
                  icon: Icons.logout,
                  label: l.logout,
                  isDestructive: true,
                  onTap: () => _confirmLogout(context, l),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l) {
    final c = context.appColors;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.confirmLogoutTitle,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l.confirmLogoutMsg,
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel, style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
            child: Text(
              l.disconnect,
              style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theme selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final notifier = sl<ThemeNotifier>();
    final l = AppLocalizations.of(context);
    final c = context.appColors;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notifier,
      builder: (_, current, __) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              _ThemeOption(
                icon: Icons.wb_sunny_rounded,
                label: l.themeDay,
                selected: current == ThemeMode.light,
                onTap: () => notifier.setTheme(ThemeMode.light),
              ),
              Divider(height: 1, color: c.border),
              _ThemeOption(
                icon: Icons.nights_stay_rounded,
                label: l.themeNight,
                selected: current == ThemeMode.dark,
                onTap: () => notifier.setTheme(ThemeMode.dark),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : c.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : c.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Language selector ────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final notifier = sl<LocaleNotifier>();
    final l = AppLocalizations.of(context);
    final c = context.appColors;

    return ValueListenableBuilder<Locale>(
      valueListenable: notifier,
      builder: (_, current, __) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              _LangOption(
                flag: '🇫🇷',
                label: l.french,
                selected: current.languageCode == 'fr',
                onTap: () => notifier.setLocale(const Locale('fr')),
              ),
              Divider(height: 1, color: c.border),
              _LangOption(
                flag: '🇲🇦',
                label: l.arabic,
                selected: current.languageCode == 'ar',
                onTap: () => notifier.setLocale(const Locale('ar')),
                isRtlLabel: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isRtlLabel;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isRtlLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : c.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                textDirection: isRtlLabel ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.black, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = isDestructive ? AppColors.red : c.textPrimary;
    final bgColor = isDestructive ? AppColors.red.withValues(alpha: 0.12) : c.surface;
    final borderColor = isDestructive ? AppColors.red.withValues(alpha: 0.3) : c.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
