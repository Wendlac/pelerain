import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/payment_countdown.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class ReservationDetailScreen extends ConsumerWidget {
  final Reservation reservation;
  const ReservationDetailScreen({super.key, required this.reservation});

  /// Lapsed payment windows surface as "expired" in the UI even if the DB
  /// hasn't been updated yet.
  ReservationStatus get _effectiveStatus {
    if (reservation.status == ReservationStatus.pending &&
        DateTime.now().isAfter(reservation.expiresAt)) {
      return ReservationStatus.expired;
    }
    return reservation.status;
  }

  Color get _statusColor {
    switch (_effectiveStatus) {
      case ReservationStatus.pending:   return AppColors.warning;
      case ReservationStatus.confirmed: return AppColors.success;
      case ReservationStatus.cancelled: return AppColors.error;
      case ReservationStatus.expired:   return AppColors.contentDisabled;
    }
  }

  String get _statusLabel {
    switch (_effectiveStatus) {
      case ReservationStatus.pending:   return 'En attente';
      case ReservationStatus.confirmed: return 'Confirmé';
      case ReservationStatus.cancelled: return 'Annulé';
      case ReservationStatus.expired:   return 'Expiré';
    }
  }

  bool get _isCancellable => _effectiveStatus == ReservationStatus.pending;

  bool get _isCancelled =>
      _effectiveStatus == ReservationStatus.cancelled ||
      _effectiveStatus == ReservationStatus.expired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: _isCancelled ? AppColors.background : AppColors.primary,
            foregroundColor: _isCancelled ? AppColors.content : Colors.white,
            pinned: true,
            elevation: 0,
            title: Text(
              'Détail du billet',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _isCancelled ? AppColors.content : Colors.white,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _isCancelled ? AppColors.content : Colors.white,
              ),
              onPressed: () {
                HapticService.light();
                context.pop();
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: _isCancelled ? AppColors.content : Colors.white,
                ),
                onPressed: () {
                  HapticService.light();
                  _shareReservation(context);
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                children: [
                  const Gap(16),

                  // ── Boarding pass card ──
                  _BoardingPassCard(
                    reservation: reservation,
                    statusColor: _statusColor,
                    statusLabel: _statusLabel,
                    isCancelled: _isCancelled,
                  ),

                  // ── Payment countdown (only while pending) ──
                  if (reservation.status == ReservationStatus.pending) ...[
                    const Gap(16),
                    PaymentCountdown.banner(expiresAt: reservation.expiresAt),
                  ],

                  const Gap(20),

                  // ── Passengers list ──
                  _PassengersCard(reservation: reservation),

                  const Gap(20),

                  // ── Payment info ──
                  _PaymentCard(reservation: reservation),

                  const Gap(20),

                  // ── Company info ──
                  _CompanyCard(reservation: reservation),

                  if (_isCancellable) ...[
                    const Gap(28),
                    _CancelButton(
                      onTap: () => _confirmCancel(context, ref),
                    ),
                  ],

                  const Gap(12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareReservation(BuildContext context) {
    final text =
        'Réservation Pelerain\n'
        'Code : ${reservation.reservationCode}\n'
        '${reservation.trip.departureCity} → ${reservation.trip.arrivalCity}\n'
        '${Formatters.dateLong(reservation.trip.departureTime)} '
        'à ${Formatters.time(reservation.trip.departureTime)}\n'
        'Compagnie : ${reservation.trip.company.name}\n'
        '${reservation.seatsCount} passager${reservation.seatsCount > 1 ? 's' : ''} · '
        '${Formatters.price(reservation.totalPrice)}';

    Clipboard.setData(ClipboardData(text: text));
    HapticService.success();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copié dans le presse-papier',
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 26),
            ),
            const Gap(16),
            Text('Annuler la réservation ?', style: AppTextStyles.headingXS, textAlign: TextAlign.center),
            const Gap(8),
            Text(
              'Cette action est irréversible. Votre code ${reservation.reservationCode} sera invalidé.',
              style: AppTextStyles.textMMedium.copyWith(color: AppColors.contentTertiary),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticService.light();
                      Navigator.of(ctx, rootNavigator: true).pop();
                    },
                    child: const Text('Garder'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    onPressed: () {
                      HapticService.error();
                      ref.read(reservationsProvider.notifier).cancel(reservation.id);
                      // Close modal first, then navigate back to list
                      Navigator.of(ctx, rootNavigator: true).pop();
                      context.go('/reservations');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Réservation annulée',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w700)),
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

// ─── Boarding Pass Card ──────────────────────────────────────────────────────

class _BoardingPassCard extends StatelessWidget {
  final Reservation reservation;
  final Color statusColor;
  final String statusLabel;
  final bool isCancelled;

  const _BoardingPassCard({
    required this.reservation,
    required this.statusColor,
    required this.statusLabel,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isCancelled
                ? Colors.black.withValues(alpha: 0.06)
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Ticket Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: isCancelled
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5A0FA8), Color(0xFF9B4FFF)],
                    ),
              color: isCancelled ? AppColors.surfaceElevated : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.trip.departureCity,
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isCancelled ? AppColors.contentSecondary : Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          Text(
                            Formatters.time(reservation.trip.departureTime),
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isCancelled ? AppColors.content : Colors.white,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow + duration
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            reservation.trip.durationLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCancelled
                                  ? AppColors.contentTertiary
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const Gap(4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: isCancelled
                                ? AppColors.contentTertiary
                                : Colors.white.withValues(alpha: 0.8),
                            size: 22,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            reservation.trip.arrivalCity,
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isCancelled ? AppColors.contentSecondary : Colors.white,
                              letterSpacing: -0.8,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          Text(
                            Formatters.time(reservation.trip.arrivalTime),
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isCancelled ? AppColors.content : Colors.white,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                // Date + company + status
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: isCancelled
                          ? AppColors.contentTertiary
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                    const Gap(4),
                    Text(
                      Formatters.dateLong(reservation.trip.departureTime),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: isCancelled
                            ? AppColors.contentTertiary
                            : Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: reservation.status == ReservationStatus.pending
                              ? AppColors.content
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Perforated divider ──
          _PerforatedDivider(isCancelled: isCancelled),

          // ── Reservation code ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Text(
                  'Code de réservation',
                  style: AppTextStyles.textSMedium.copyWith(
                    color: AppColors.contentTertiary,
                  ),
                ),
                const Gap(8),
                GestureDetector(
                  onTap: () {
                    HapticService.success();
                    Clipboard.setData(ClipboardData(text: reservation.reservationCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Code copié !',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isCancelled
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFF4EBFF), Color(0xFFEBD9FF)],
                            ),
                      color: isCancelled ? AppColors.surface : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCancelled ? AppColors.border : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reservation.reservationCode,
                          style: GoogleFonts.dmSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isCancelled ? AppColors.contentDisabled : AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Gap(10),
                        Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: isCancelled ? AppColors.contentDisabled : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(4),
                Text(
                  'Appuyez pour copier',
                  style: AppTextStyles.textXSMedium.copyWith(
                    color: AppColors.contentTertiary,
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

// ─── Perforated Divider ──────────────────────────────────────────────────────

class _PerforatedDivider extends StatelessWidget {
  final bool isCancelled;
  const _PerforatedDivider({required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left notch
          Positioned(
            left: -14,
            top: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right notch
          Positioned(
            right: -14,
            top: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Dashed line
          Center(
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(
                color: isCancelled ? AppColors.border : AppColors.borderLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double x = 20;
    while (x < size.width - 20) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, 0), paint);
      x += 14;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Passengers Card ────────────────────────────────────────────────────────

class _PassengersCard extends StatelessWidget {
  final Reservation reservation;
  const _PassengersCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Passagers',
      icon: Icons.people_rounded,
      child: Column(
        children: reservation.passengers.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < reservation.passengers.length - 1 ? 12 : 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.firstName} ${p.lastName}',
                        style: AppTextStyles.textMMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.content,
                        ),
                      ),
                      Text(
                        p.typeLabel,
                        style: AppTextStyles.textSMedium.copyWith(
                          color: AppColors.contentTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Siège ${i + 1}',
                    style: AppTextStyles.textXSMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Payment Card ────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Reservation reservation;
  const _PaymentCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final unitPrice = reservation.trip.price;
    final count = reservation.passengers.length;
    final total = reservation.totalPrice;

    return _InfoCard(
      title: 'Récapitulatif',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _PriceRow(
            label: '${Formatters.price(unitPrice)} × $count passager${count > 1 ? 's' : ''}',
            value: Formatters.price(unitPrice * count),
          ),
          const Gap(10),
          const Divider(color: AppColors.divider, height: 1),
          const Gap(10),
          _PriceRow(
            label: 'Total à payer en agence',
            value: Formatters.price(total),
            isTotal: true,
          ),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Paiement à effectuer directement à l\'agence.',
                    style: AppTextStyles.textSMedium.copyWith(
                      color: AppColors.content,
                    ),
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

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.textMMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.content)
              : AppTextStyles.textMMedium.copyWith(color: AppColors.contentSecondary),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.textMBold.copyWith(color: AppColors.primary, fontSize: 16)
              : AppTextStyles.textMMedium.copyWith(color: AppColors.content),
        ),
      ],
    );
  }
}

// ─── Company Card ────────────────────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  final Reservation reservation;
  const _CompanyCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final company = reservation.trip.company;
    return _InfoCard(
      title: 'Compagnie',
      icon: Icons.directions_bus_rounded,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Text(
                company.name.substring(0, 1),
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: AppTextStyles.textMMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                  ),
                ),
                const Gap(2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const Gap(3),
                    Text(
                      company.rating.toStringAsFixed(1),
                      style: AppTextStyles.textSMedium.copyWith(
                        color: AppColors.contentSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' · ${company.totalTrips} trajets',
                      style: AppTextStyles.textSMedium.copyWith(
                        color: AppColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
              const Gap(2),
              Text(
                company.phone,
                style: AppTextStyles.textXSMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Generic info card wrapper ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const Gap(6),
              Text(
                title,
                style: AppTextStyles.textSBold.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const Gap(14),
          const Divider(color: AppColors.divider, height: 1),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

// ─── Cancel button ───────────────────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
            const Gap(8),
            Text(
              'Annuler cette réservation',
              style: AppTextStyles.textMMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
