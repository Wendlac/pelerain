import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../constants/app_colors.dart';

/// Live countdown showing how long the user has left to pay at the agency.
///
/// Two presentations:
/// - `PaymentCountdown.banner` — large pill with icon + "Hh MMm restant",
///   suitable for the reservation detail boarding pass.
/// - `PaymentCountdown.compact` — single line with just the time, suitable
///   for the reservation list card.
///
/// The colour transitions from purple → orange → red as the deadline approaches,
/// and switches to a muted grey "Expiré" pill once the time is up.
class PaymentCountdown extends StatefulWidget {
  /// Time at which the payment window closes.
  final DateTime expiresAt;

  /// Whether to render the large banner (`true`) or the compact pill (`false`).
  final bool isBanner;

  const PaymentCountdown.banner({super.key, required this.expiresAt})
      : isBanner = true;

  const PaymentCountdown.compact({super.key, required this.expiresAt})
      : isBanner = false;

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    // Tick every second so the "MMs" counter feels live. The widget is cheap.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.expiresAt.difference(DateTime.now());
      });
    });
  }

  @override
  void didUpdateWidget(covariant PaymentCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _remaining = widget.expiresAt.difference(DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _expired => _remaining.isNegative || _remaining == Duration.zero;

  /// Returns a (foreground, background) colour pair based on urgency.
  ({Color fg, Color bg}) _colors() {
    if (_expired) {
      return (
        fg: AppColors.contentTertiary,
        bg: AppColors.surfaceNeutral,
      );
    }
    if (_remaining.inMinutes < 30) {
      return (
        fg: AppColors.error,
        bg: AppColors.error.withValues(alpha: 0.1),
      );
    }
    if (_remaining.inHours < 2) {
      return (
        fg: AppColors.warningDark,
        bg: AppColors.warning.withValues(alpha: 0.18),
      );
    }
    return (
      fg: AppColors.primary,
      bg: AppColors.primary.withValues(alpha: 0.1),
    );
  }

  String _formatBanner() {
    if (_expired) return 'Délai dépassé';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m restant';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s restant';
    return '${s}s restant';
  }

  String _formatCompact() {
    if (_expired) return 'Expiré';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    if (!widget.isBanner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 12,
              color: colors.fg,
            ),
            const Gap(4),
            Text(
              _formatCompact(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.fg,
              ),
            ),
          ],
        ),
      );
    }

    // Banner variant
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.fg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _expired ? Icons.timer_off_rounded : Icons.timer_rounded,
              size: 18,
              color: colors.fg,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _expired
                      ? 'Réservation expirée'
                      : 'Payez en agence dans',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.fg.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  _formatBanner(),
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.fg,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
