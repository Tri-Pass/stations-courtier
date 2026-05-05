import 'package:flutter/material.dart';
import 'package:courtier/core/theme/app_theme.dart';

void showAppSuccess(
  BuildContext context, {
  required String title,
  List<(String, String)>? details,
}) {
  _show(context, title: title, details: details, isSuccess: true);
}

void showAppError(
  BuildContext context, {
  required String message,
}) {
  _show(context, title: message, isSuccess: false);
}

void _show(
  BuildContext context, {
  required String title,
  List<(String, String)>? details,
  required bool isSuccess,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  bool removed = false;

  entry = OverlayEntry(
    builder: (_) => _AppNotificationOverlay(
      title: title,
      details: details,
      isSuccess: isSuccess,
      onDismiss: () {
        if (!removed) {
          removed = true;
          entry.remove();
        }
      },
    ),
  );
  overlay.insert(entry);
}

class _AppNotificationOverlay extends StatefulWidget {
  final String title;
  final List<(String, String)>? details;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _AppNotificationOverlay({
    required this.title,
    required this.details,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_AppNotificationOverlay> createState() =>
      _AppNotificationOverlayState();
}

class _AppNotificationOverlayState extends State<_AppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(
      Duration(seconds: widget.isSuccess ? 3 : 5),
      _dismiss,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSuccess ? AppColors.green : AppColors.red;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isSuccess
                            ? Icons.check_rounded
                            : Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (widget.details != null &&
                              widget.details!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...widget.details!.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Text(
                                      '${d.$1}:  ',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      d.$2,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
