import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:courtier/core/di/injection.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/services/sunmi_nfc_service.dart';
import 'package:courtier/core/theme/app_theme.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart';
import 'package:courtier/features/queue/domain/repositories/queue_repository.dart';

enum _Step { search, scan, otp, success }

// ─── Root ─────────────────────────────────────────────────────────────────────

class LinkNfcPage extends StatefulWidget {
  const LinkNfcPage({super.key});

  @override
  State<LinkNfcPage> createState() => _LinkNfcPageState();
}

class _LinkNfcPageState extends State<LinkNfcPage> {
  final _repo = sl<QueueRepository>();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  _Step _step = _Step.search;
  DriverInfo? _driver;
  String? _nfcTagId;
  String _otpValue = '';
  String? _error;
  bool _searching = false;
  bool _loading = false;

  StreamSubscription<Map<String, dynamic>>? _nfcSub;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onPhoneEdited);
  }

  void _onPhoneEdited() {
    if (_driver != null && mounted) {
      setState(() { _driver = null; _error = null; });
    }
  }

  @override
  void dispose() {
    _nfcSub?.cancel();
    _phoneCtrl.removeListener(_onPhoneEdited);
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _searchDriver() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    _phoneFocus.unfocus();
    setState(() { _searching = true; _error = null; _driver = null; });
    try {
      final driver = await _repo.searchDriver(phone);
      if (!mounted) return;
      setState(() => _driver = driver);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goScan() {
    setState(() { _step = _Step.scan; _error = null; _nfcTagId = null; });
    _startNfc();
  }

  void _startNfc() {
    _nfcSub?.cancel();
    _nfcSub = SunmiNfcService.allEventsStream().listen((event) {
      if (event['event'] == 'CARD_FOUND') {
        final tagId = event['details']?.toString() ?? '';
        if (tagId.isNotEmpty && mounted) {
          _nfcSub?.cancel();
          _nfcSub = null;
          setState(() => _nfcTagId = tagId);
        }
      }
    });
  }

  Future<void> _goOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.sendOtp(_driver!.id);
      if (!mounted) return;
      setState(() => _step = _Step.otp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _linkNfc() async {
    if (_otpValue.length < 4) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.validateOtp(_driver!.id, _otpValue, _nfcTagId!);
      if (!mounted) return;
      setState(() => _step = _Step.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    _nfcSub?.cancel();
    _nfcSub = null;
    setState(() => _error = null);
    if (_step == _Step.scan) {
      setState(() { _step = _Step.search; _nfcTagId = null; });
    } else if (_step == _Step.otp) {
      setState(() { _step = _Step.scan; _otpValue = ''; });
      _startNfc();
    }
  }

  void _reset() {
    _nfcSub?.cancel();
    _nfcSub = null;
    _phoneCtrl.clear();
    setState(() {
      _step = _Step.search;
      _driver = null;
      _nfcTagId = null;
      _otpValue = '';
      _error = null;
      _searching = false;
      _loading = false;
    });
  }

  String _msg(Object e) {
    final s = e.toString();
    final l = AppLocalizations.of(context);
    if (s.contains('404')) return l.driverNotFound;
    if (s.contains('409')) return l.nfcAlreadyLinked;
    if (s.contains('400')) return l.otpInvalid;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    switch (_step) {
      case _Step.search:
        page = _SearchPage(
          key: const ValueKey(_Step.search),
          phoneCtrl: _phoneCtrl,
          phoneFocus: _phoneFocus,
          driver: _driver,
          searching: _searching,
          error: _error,
          onSearch: _searchDriver,
          onNext: _goScan,
        );
        break;
      case _Step.scan:
        page = _ScanPage(
          key: const ValueKey(_Step.scan),
          driver: _driver!,
          nfcTagId: _nfcTagId,
          loading: _loading,
          error: _error,
          onBack: _back,
          onNext: _goOtp,
        );
        break;
      case _Step.otp:
        page = _OtpPage(
          key: const ValueKey(_Step.otp),
          driver: _driver!,
          nfcTagId: _nfcTagId!,
          otpValue: _otpValue,
          loading: _loading,
          error: _error,
          onChanged: (v) => setState(() => _otpValue = v),
          onBack: _back,
          onLink: _linkNfc,
        );
        break;
      case _Step.success:
        page = _SuccessPage(
          key: const ValueKey(_Step.success),
          driver: _driver!,
          nfcTagId: _nfcTagId!,
          onDone: _reset,
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: page,
    );
  }
}

// ─── Page 1 — Search driver ───────────────────────────────────────────────────

class _SearchPage extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final FocusNode phoneFocus;
  final DriverInfo? driver;
  final bool searching;
  final String? error;
  final VoidCallback onSearch;
  final VoidCallback onNext;

  const _SearchPage({
    super.key,
    required this.phoneCtrl,
    required this.phoneFocus,
    required this.driver,
    required this.searching,
    required this.error,
    required this.onSearch,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.appColors;
    final hasDriver = driver != null;

    return _PageShell(
      header: _Header(title: l.linkNfcTitle, step: 1, total: 3),
      bottom: _NextButton(
        label: hasDriver ? l.continueBtn : l.search,
        enabled: !searching,
        loading: searching,
        onPressed: hasDriver ? onNext : onSearch,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            l.searchDriverPhone,
            style: TextStyle(color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(l.searchByPhone, style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),

          _InputBox(
            controller: phoneCtrl,
            focusNode: phoneFocus,
            hint: '06XXXXXXXX',
            icon: Icons.phone_rounded,
            inputType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => hasDriver ? onNext() : onSearch(),
          ),

          if (error != null) ...[const SizedBox(height: 14), _ErrorBanner(message: error!)],

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: hasDriver
                ? Padding(
                    key: ValueKey(driver!.id),
                    padding: const EdgeInsets.only(top: 24),
                    child: _DriverCard(driver: driver!),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2 — Scan NFC tag ────────────────────────────────────────────────────

class _ScanPage extends StatelessWidget {
  final DriverInfo driver;
  final String? nfcTagId;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _ScanPage({
    super.key,
    required this.driver,
    required this.nfcTagId,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.appColors;
    final detected = nfcTagId != null;

    return _PageShell(
      header: _Header(title: l.stepScan, step: 2, total: 3, onBack: onBack),
      bottom: _NextButton(
        label: l.continueBtn,
        enabled: detected && !loading,
        loading: loading,
        onPressed: onNext,
      ),
      child: Column(
        children: [
          _DriverCardCompact(driver: driver),
          const SizedBox(height: 36),

          _NfcRadar(detected: detected),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: detected
                ? Column(
                    key: const ValueKey('detected'),
                    children: [
                      Text(
                        l.nfcTagDetected,
                        style: const TextStyle(color: Color(0xFF4CAF7D), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF7D).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF7D).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          nfcTagId!,
                          style: const TextStyle(color: Color(0xFF4CAF7D), fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('waiting'),
                    children: [
                      Text(
                        l.scanNfcInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.scanNfcWaiting,
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
          ),

          if (error != null) ...[const SizedBox(height: 20), _ErrorBanner(message: error!)],
        ],
      ),
    );
  }
}

// ─── Page 3 — OTP entry ───────────────────────────────────────────────────────

class _OtpPage extends StatelessWidget {
  final DriverInfo driver;
  final String nfcTagId;
  final String otpValue;
  final bool loading;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onLink;

  const _OtpPage({
    super.key,
    required this.driver,
    required this.nfcTagId,
    required this.otpValue,
    required this.loading,
    required this.error,
    required this.onChanged,
    required this.onBack,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.appColors;

    return _PageShell(
      header: _Header(title: l.stepOtp, step: 3, total: 3, onBack: onBack),
      bottom: _NextButton(
        label: l.validateAndLink,
        enabled: otpValue.length == 4 && !loading,
        loading: loading,
        onPressed: onLink,
        isAction: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DriverCardCompact(driver: driver),
          const SizedBox(height: 10),
          _NfcTagRow(tagId: nfcTagId),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(Icons.sms_rounded, color: c.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l.otpSentInfo} ${driver.phone}',
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(l.enterOtp, style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          Center(child: _OtpBoxes(value: otpValue, onChanged: onChanged)),

          if (error != null) ...[const SizedBox(height: 20), _ErrorBanner(message: error!)],
        ],
      ),
    );
  }
}

// ─── Page 4 — Success ─────────────────────────────────────────────────────────

class _SuccessPage extends StatefulWidget {
  final DriverInfo driver;
  final String nfcTagId;
  final VoidCallback onDone;

  const _SuccessPage({super.key, required this.driver, required this.nfcTagId, required this.onDone});

  @override
  State<_SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<_SuccessPage> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => FadeTransition(
                  opacity: _fade,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF7D).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4CAF7D).withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF4CAF7D), size: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l.linkSuccess,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                l.linkSuccessSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              _DriverCard(driver: widget.driver),
              const SizedBox(height: 10),
              _NfcTagRow(tagId: widget.nfcTagId),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(l.linkAnotherDriver, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared layout shells ─────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final Widget header;
  final Widget bottom;
  final Widget child;

  const _PageShell({required this.header, required this.bottom, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final int step;
  final int total;
  final VoidCallback? onBack;

  const _Header({required this.title, required this.step, required this.total, this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 18),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 12),
          const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, (i) {
                final active = i == step - 1;
                final done = i < step - 1;
                return Container(
                  width: active ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: done || active ? AppColors.primary : c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next / action button ─────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final bool isAction;
  final VoidCallback onPressed;

  const _NextButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.primary : c.surface,
          foregroundColor: enabled ? Colors.black : c.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: enabled ? Colors.transparent : c.border),
          ),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (!isAction) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 18)],
                ],
              ),
      ),
    );
  }
}

// ─── Driver card (full) ───────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverInfo driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.appColors;
    final initials = driver.name.isNotEmpty
        ? driver.name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: c.textSecondary, size: 13),
                        const SizedBox(width: 4),
                        Text(driver.phone,
                            style: TextStyle(color: c.textSecondary, fontSize: 13)),
                      ],
                    ),
                    if (driver.driverCode.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, color: c.textSecondary, size: 13),
                          const SizedBox(width: 4),
                          Text('${l.driverCode} : ${driver.driverCode}',
                              style: TextStyle(color: c.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _NfcLinkedBadge(linked: driver.nfcLinked),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: c.border, height: 1),
          ),

          Row(
            children: [
              if (driver.taxiNumber != null && driver.taxiNumber!.isNotEmpty)
                _InfoPill(
                  icon: Icons.local_taxi_rounded,
                  label: l.taxiNumberLabel,
                  value: driver.taxiNumber!,
                  color: AppColors.primary,
                ),
              if (driver.taxiNumber != null &&
                  driver.taxiNumber!.isNotEmpty &&
                  driver.plateNumber != null &&
                  driver.plateNumber!.isNotEmpty)
                const SizedBox(width: 10),
              if (driver.plateNumber != null && driver.plateNumber!.isNotEmpty)
                _InfoPill(
                  icon: Icons.credit_card_rounded,
                  label: l.plateNumber,
                  value: driver.plateNumber!,
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NfcLinkedBadge extends StatelessWidget {
  final bool linked;
  const _NfcLinkedBadge({required this.linked});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = linked ? const Color(0xFF4CAF7D) : context.appColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nfc_rounded, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            linked ? l.nfcLinkedBadge : l.nfcNotLinkedBadge,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: c.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Driver card (compact) ────────────────────────────────────────────────────

class _DriverCardCompact extends StatelessWidget {
  final DriverInfo driver;
  const _DriverCardCompact({required this.driver});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final initials = driver.name.isNotEmpty
        ? driver.name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text(initials, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(driver.phone, style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}

// ─── NFC tag row ──────────────────────────────────────────────────────────────

class _NfcTagRow extends StatelessWidget {
  final String tagId;
  const _NfcTagRow({required this.tagId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tagId,
              style: const TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}

// ─── NFC radar animation ──────────────────────────────────────────────────────

class _NfcRadar extends StatefulWidget {
  final bool detected;
  const _NfcRadar({required this.detected});

  @override
  State<_NfcRadar> createState() => _NfcRadarState();
}

class _NfcRadarState extends State<_NfcRadar> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _ctrls.add(AnimationController(vsync: this, duration: const Duration(milliseconds: 1800)));
    }
    _startStaggered();
  }

  Future<void> _startStaggered() async {
    for (int i = 0; i < _ctrls.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 600));
      if (mounted) _ctrls[i].repeat();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: widget.detected ? _buildDetected() : _buildScanning(),
    );
  }

  Widget _buildDetected() {
    return Container(
      key: const ValueKey('detected'),
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF7D).withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4CAF7D).withValues(alpha: 0.5), width: 2.5),
      ),
      child: const Icon(Icons.nfc_rounded, color: Color(0xFF4CAF7D), size: 64),
    );
  }

  Widget _buildScanning() {
    return SizedBox(
      key: const ValueKey('scanning'),
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < _ctrls.length; i++)
            AnimatedBuilder(
              animation: _ctrls[i],
              builder: (_, __) {
                final v = _ctrls[i].value;
                return Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0),
                  child: Container(
                    width: 80 + v * 120,
                    height: 80 + v * 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 44),
          ),
        ],
      ),
    );
  }
}

// ─── OTP 4-box input ──────────────────────────────────────────────────────────

class _OtpBoxes extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _OtpBoxes({required this.value, required this.onChanged});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.value;
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _OtpBoxes old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final char = i < widget.value.length ? widget.value[i] : null;
                final isCursor = i == widget.value.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 60,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: char != null
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: char != null
                          ? AppColors.primary
                          : isCursor
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : c.border,
                      width: char != null || isCursor ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: char != null
                        ? Text(
                            char,
                            style: TextStyle(color: c.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                          )
                        : Container(width: 14, height: 2, color: isCursor ? AppColors.primary : c.border),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input box ────────────────────────────────────────────────────────────────

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onSubmitted;

  const _InputBox({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.inputType = TextInputType.text,
    this.formatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: inputType,
        inputFormatters: formatters,
        onSubmitted: onSubmitted,
        style: TextStyle(color: c.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary),
          prefixIcon: Icon(icon, color: c.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.red, fontSize: 13))),
        ],
      ),
    );
  }
}
