import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:courtier/core/di/injection.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/network/api_client.dart';
import 'package:courtier/core/theme/app_theme.dart';
import 'package:courtier/core/widgets/app_notification.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart';
import 'package:courtier/features/queue/domain/repositories/queue_repository.dart';

class NfcConfirmPage extends StatefulWidget {
  final String nfcTagId;
  const NfcConfirmPage({super.key, required this.nfcTagId});

  @override
  State<NfcConfirmPage> createState() => _NfcConfirmPageState();
}

class _NfcConfirmPageState extends State<NfcConfirmPage> {
  NfcDriverInfo? _driver;
  List<Line> _lines = [];
  Line? _selectedLine;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        sl<QueueRepository>().lookupByNfc(widget.nfcTagId),
        sl<QueueRepository>().fetchLines(),
      ]);
      if (mounted) {
        setState(() {
          _driver = results[0] as NfcDriverInfo;
          _lines  = results[1] as List<Line>;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) { setState(() => _loading = false); showAppError(context, message: e.message); }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        showAppError(context, message: AppLocalizations.of(context).connectionErrorShort);
      }
    }
  }

  Future<void> _addToQueue() async {
    if (_driver == null) return;
    if (_selectedLine == null) {
      showAppError(context, message: AppLocalizations.of(context).lineRequired);
      return;
    }
    setState(() => _adding = true);
    try {
      await sl<QueueRepository>().enqueue(_driver!.id, _selectedLine!.id);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) showAppError(context, message: e.message);
    } catch (_) {
      if (mounted) {
        showAppError(context, message: AppLocalizations.of(context).connectionErrorShort);
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          l.nfcDetected,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _driver == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── NFC badge ──────────────────────────────
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: const Icon(Icons.nfc,
                                    color: AppColors.primary, size: 32),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                l.nfcIdentified,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    letterSpacing: 0.4),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Driver info card ───────────────────────
                            _DriverCard(driver: _driver!, l: l),
                            const SizedBox(height: 24),

                            // ── Section header ─────────────────────────
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.selectLine,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const Spacer(),
                                if (_lines.isNotEmpty)
                                  Text(
                                    '${_lines.length} ${l.lineLabel.toLowerCase()}s',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Line cards ─────────────────────────────
                            if (_lines.isEmpty)
                              const _EmptyLines()
                            else
                              ...(_lines.map((line) => _LineCard(
                                    line: line,
                                    isSelected:
                                        _selectedLine?.id == line.id,
                                    onTap: () => setState(
                                        () => _selectedLine = line),
                                  ))),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // ── Fixed bottom action ────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                            top: BorderSide(color: AppColors.border)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // if (_selectedLine != null)
                          //   Padding(
                          //     padding: const EdgeInsets.only(bottom: 12),
                          //     child: Row(
                          //       children: [
                          //         const Icon(Icons.check_circle_rounded,
                          //             color: AppColors.primary, size: 16),
                          //         const SizedBox(width: 6),
                          //         Expanded(
                          //           child: Text(
                          //             _selectedLine!.label,
                          //             style: const TextStyle(
                          //               color: AppColors.primary,
                          //               fontSize: 13,
                          //               fontWeight: FontWeight.w600,
                          //             ),
                          //             overflow: TextOverflow.ellipsis,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _adding ? null : _addToQueue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _adding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black),
                                    )
                                  : Text(l.addToQueue,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: Text(l.cancel,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final NfcDriverInfo driver;
  final AppLocalizations l;
  const _DriverCard({required this.driver, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.confirmation_number_outlined, label: l.taxiNumberLabel, value: driver.taxiNumber),
          const _Divider(),
          _InfoRow(icon: Icons.person_outline, label: l.driverLabel, value: driver.name),
          const _Divider(),
          _InfoRow(icon: Icons.phone_outlined, label: l.phone, value: driver.phone),
          const _Divider(),
          _InfoRow(icon: Icons.location_on_outlined, label: l.destination, value: driver.destination),
          const _Divider(),
          _InfoRow(icon: Icons.event_seat_outlined, label: l.seats, value: '${driver.seatsTotal} ${l.seatsAvailable}'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 1, thickness: 1);
}

// ─── Line card ────────────────────────────────────────────────────────────────

class _LineCard extends StatelessWidget {
  final Line line;
  final bool isSelected;
  final VoidCallback onTap;
  const _LineCard(
      {required this.line, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Route dots + connector
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 22,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Origin + destination labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.origin,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    line.destination,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Price + radio
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 14)
                      : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.inputBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${line.price} MAD',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty lines ──────────────────────────────────────────────────────────────

class _EmptyLines extends StatelessWidget {
  const _EmptyLines();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.route_outlined,
              color: AppColors.textSecondary, size: 40),
          SizedBox(height: 10),
          Text('Aucune ligne disponible',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
