import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:courtier/core/di/injection.dart';
import 'package:courtier/core/l10n/app_localizations.dart';
import 'package:courtier/core/theme/app_theme.dart';
import 'package:courtier/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:courtier/features/queue/domain/entities/queue_entry.dart'
    show Line, QueueEntry;
import 'package:courtier/features/queue/presentation/bloc/queue_bloc.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QueueBloc>()..add(QueueLoad()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();
  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedLineName;
  String? _selectedLineId;
  String? _activePhoneFilter;
  Timer? _debounce;

  List<Line> _sortedLines(QueueLoaded state) {
    final lines = List<Line>.from(state.lines);
    lines.sort((a, b) => a.label.compareTo(b.label));
    return lines;
  }

  void _dispatchFilter() {
    if (!mounted) return;
    final apiLineId = (_selectedLineId != null &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_selectedLineId!))
        ? _selectedLineId
        : null;
    context.read<QueueBloc>().add(
      QueueApplyFilter(driverPhone: _activePhoneFilter, lineId: apiLineId),
    );
  }

  void _onSearchChanged(String v) {
    // Always update local search query — triggers rebuild → _applyFilters runs
    setState(() => _searchQuery = v);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      // Only hit the API when the query looks like a phone number
      final isPhone = RegExp(r'^\d{10,}$').hasMatch(v.trim());
      final newPhone = isPhone ? v.trim() : null;
      if (newPhone != _activePhoneFilter) {
        _activePhoneFilter = newPhone;
        _dispatchFilter();
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    final hadPhone = _activePhoneFilter != null;
    setState(() {
      _searchQuery = '';
      _activePhoneFilter = null;
    });
    if (hadPhone) _dispatchFilter();
  }

  List<QueueEntry> _applyTextSearch(List<QueueEntry> source) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return source;
    return source.where((t) =>
        t.driverName.toLowerCase().contains(q) ||
        t.taxiNumber.toLowerCase().contains(q) ||
        t.driverPhone.contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showLineSheet(List<Line> lines) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final l = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _LineOption(
                  label: l.allLines,
                  isSelected: _selectedLineId == null,
                  onTap: () {
                    setState(() {
                      _selectedLineName = null;
                      _selectedLineId = null;
                    });
                    _dispatchFilter();
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ...lines.map((line) => _LineOption(
                  label: line.label,
                  isSelected: _selectedLineId == line.id,
                  onTap: () {
                    setState(() {
                      _selectedLineName = line.label;
                      _selectedLineId = line.id;
                    });
                    _dispatchFilter();
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<QueueBloc, QueueState>(
          builder: (context, queueState) {
            final loaded =
            queueState is QueueLoaded ? queueState : null;

            // Use allWaiting/allActive/allCompleted as the base for local filtering.
            // These always hold the full unfiltered dataset so name/taxi search
            // works correctly even when a line or phone API filter is active.
            // When a line filter is active, the API has already filtered
            // waiting/active/completed — use those directly.
            // For text search only, filter the full unfiltered lists locally.
            final lineActive = _selectedLineId != null;
            final filteredWaiting = loaded != null
                ? _applyTextSearch(lineActive ? loaded.waiting : loaded.allWaiting)
                : <QueueEntry>[];
            final filteredActive = loaded != null
                ? _applyTextSearch(lineActive ? loaded.active : loaded.allActive)
                : <QueueEntry>[];
            final filteredCompleted = loaded != null
                ? _applyTextSearch(lineActive ? loaded.completed : loaded.allCompleted)
                : <QueueEntry>[];

            final lines =
            loaded != null ? _sortedLines(loaded) : <Line>[];

            return Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final driver =
                      state is AuthAuthenticated ? state.driver : null;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver?.station?.name ?? 'Station',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  driver?.name ?? '',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.person_outline,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // ── Search + Filter bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: l.searchDriver,
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.textSecondary, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                onTap: _clearSearch,
                                child: const Icon(Icons.close,
                                    color: AppColors.textSecondary,
                                    size: 16),
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showLineSheet(lines),
                        child: Container(
                          height: 40,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedLineId != null
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedLineId != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: _selectedLineId != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l.lineLabel,
                                style: TextStyle(
                                  color: _selectedLineId != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Active filter chip ──────────────────────────────────
                if (_selectedLineId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _FilterChip(
                        label: _selectedLineName ?? '',
                        onRemove: () {
                          setState(() {
                            _selectedLineName = null;
                            _selectedLineId = null;
                          });
                          _dispatchFilter();
                        },
                      ),
                    ),
                  ),
                SizedBox(height: _selectedLineId != null ? 8 : 12),
                // ── Tab bar ─────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      _TabLabel(
                          label: l.tabWaiting,
                          color: const Color(0xFFF5A300),
                          count: filteredWaiting.length),
                      _TabLabel(
                          label: l.tabActive,
                          color: const Color(0xFF4CAF7D),
                          count: filteredActive.length),
                      _TabLabel(
                          label: l.tabCompleted,
                          color: AppColors.red,
                          count: filteredCompleted.length),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Tab views ───────────────────────────────────────────
                Expanded(
                  child: queueState is QueueLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                      : queueState is QueueError
                      ? _ErrorView(
                    message: queueState.message,
                    onRetry: () => context
                        .read<QueueBloc>()
                        .add(QueueLoad()),
                  )
                      : TabBarView(
                    controller: _tabController,
                    children: [
                      _TaxiList(
                        entries: filteredWaiting,
                        showSeats: false,
                        onRefresh: () async => context
                            .read<QueueBloc>()
                            .add(QueueRefresh()),
                      ),
                      _TaxiList(
                        entries: filteredActive,
                        showSeats: true,
                        onRefresh: () async => context
                            .read<QueueBloc>()
                            .add(QueueRefresh()),
                      ),
                      _TaxiList(
                        entries: filteredCompleted,
                        showSeats: false,
                        onRefresh: () async => context
                            .read<QueueBloc>()
                            .add(QueueRefresh()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ─── Line option ──────────────────────────────────────────────────────────────
class _LineOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LineOption(
      {required this.label,
        required this.isSelected,
        required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontSize: 15,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Tab label ────────────────────────────────────────────────────────────────
class _TabLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _TabLabel(
      {required this.label, required this.color, required this.count});
  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$count',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Taxi list ────────────────────────────────────────────────────────────────
class _TaxiList extends StatelessWidget {
  final List<QueueEntry> entries;
  final bool showSeats;
  final Future<void> Function() onRefresh;
  const _TaxiList(
      {required this.entries,
        required this.showSeats,
        required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(l.noTaxi,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: entries.length,
        itemBuilder: (_, i) =>
            _TaxiCard(entry: entries[i], showSeats: showSeats),
      ),
    );
  }
}

// ─── Taxi card ────────────────────────────────────────────────────────────────
class _TaxiCard extends StatelessWidget {
  final QueueEntry entry;
  final bool showSeats;
  const _TaxiCard({required this.entry, required this.showSeats});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🚕 ${entry.taxiNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              if (showSeats) ...[
                const Spacer(),
                _SeatDots(
                    occupied: entry.seatsOccupied,
                    total: entry.seatsTotal),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
              icon: '👤',
              text: '${l.driverLabel}: ${entry.driverName}'),
          const SizedBox(height: 6),
          _InfoRow(icon: '📞', text: entry.driverPhone),
          const SizedBox(height: 6),
          _InfoRow(
              icon: '📍',
              text: '${entry.lineOrigin} → ${entry.lineDestination}'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }
}

// ─── Seat dots ────────────────────────────────────────────────────────────────
class _SeatDots extends StatelessWidget {
  final int occupied;
  final int total;
  const _SeatDots({required this.occupied, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(
            total,
                (i) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: i < occupied
                    ? const Color(0xFF4CAF7D)
                    : AppColors.inputBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: i < occupied
                        ? const Color(0xFF4CAF7D)
                        : AppColors.border),
              ),
            )),
        const SizedBox(width: 4),
        Text(
          '$occupied/$total',
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}