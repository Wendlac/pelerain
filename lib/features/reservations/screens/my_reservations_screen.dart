import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_card.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: reservations.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    title: 'Mes billets',
                    count: null,
                  ),
                  const Expanded(child: _EmptyReservations()),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageHeader(
                      title: 'Mes billets',
                      count: reservations.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: reservations.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (ctx, i) {
                        final r = reservations[reservations.length - 1 - i];
                        return _ReservationCard(
                          reservation: r,
                          onTap: () {
                            HapticService.selection();
                            ctx.push('/reservation-detail', extra: r);
                          },
                          onCancel: r.status == ReservationStatus.pending
                              ? () => _confirmCancel(ctx, ref, r.id)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, String id) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            ),
            const Gap(16),
            Text(
              'Annuler la réservation ?',
              style: AppTextStyles.headingXS,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'Cette action est irréversible.',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      HapticService.error();
                      ref.read(reservationsProvider.notifier).cancel(id);
                      Navigator.of(ctx, rootNavigator: true).pop();
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

// ─── Page Header (large Wise-style title) ────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _PageHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.content,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          if (count != null && count! > 0) ...[
            const Gap(10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const _ReservationCard({required this.reservation, this.onTap, this.onCancel});

  Color get _statusColor {
    switch (reservation.status) {
      case ReservationStatus.pending: return AppColors.warning;
      case ReservationStatus.confirmed: return AppColors.success;
      case ReservationStatus.cancelled: return AppColors.error;
      case ReservationStatus.expired: return AppColors.contentDisabled;
    }
  }

  Color get _statusTextColor {
    return reservation.status == ReservationStatus.pending
        ? AppColors.content
        : Colors.white;
  }

  String get _statusLabel {
    switch (reservation.status) {
      case ReservationStatus.pending: return 'En attente';
      case ReservationStatus.confirmed: return 'Confirmé';
      case ReservationStatus.cancelled: return 'Annulé';
      case ReservationStatus.expired: return 'Expiré';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = reservation.status == ReservationStatus.cancelled ||
        reservation.status == ReservationStatus.expired;

    return Opacity(
      opacity: isCancelled ? 0.6 : 1.0,
      child: SkeuCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: isCancelled
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5A0FA8), Color(0xFF761CEA)],
                      ),
                color: isCancelled ? AppColors.surfaceElevated : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    color: isCancelled ? AppColors.contentDisabled : Colors.white,
                    size: 20,
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      '${reservation.trip.departureCity} → ${reservation.trip.arrivalCity}',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isCancelled ? AppColors.contentSecondary : Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? _statusColor.withValues(alpha: 0.15)
                          : _statusColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCancelled
                            ? (reservation.status == ReservationStatus.cancelled
                                ? AppColors.error
                                : AppColors.contentDisabled)
                            : _statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Time row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Formatters.time(reservation.trip.departureTime),
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.content,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              Formatters.date(reservation.trip.departureTime),
                              style: AppTextStyles.textSMedium.copyWith(
                                color: AppColors.contentTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            reservation.trip.durationLabel,
                            style: AppTextStyles.textXSMedium.copyWith(
                              color: AppColors.contentTertiary,
                            ),
                          ),
                          const Gap(2),
                          Container(
                            width: 60,
                            height: 1.5,
                            color: AppColors.border,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.time(reservation.trip.arrivalTime),
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.content,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              reservation.trip.arrivalCity,
                              style: AppTextStyles.textSMedium.copyWith(
                                color: AppColors.contentTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Gap(14),
                  const Divider(color: AppColors.divider, height: 1),
                  const Gap(14),

                  // Details row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        icon: Icons.tag_rounded,
                        label: reservation.reservationCode,
                        prominent: true,
                      ),
                      _InfoChip(
                        icon: Icons.people_rounded,
                        label: '${reservation.seatsCount} passager${reservation.seatsCount > 1 ? 's' : ''}',
                      ),
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: Formatters.price(reservation.totalPrice),
                        prominent: true,
                      ),
                    ],
                  ),

                  if (onCancel != null) ...[
                    const Gap(14),
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const Gap(6),
                            Text(
                              'Annuler la réservation',
                              style: AppTextStyles.textSBold.copyWith(
                                color: AppColors.error,
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool prominent;
  const _InfoChip({required this.icon, required this.label, this.prominent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: prominent ? AppColors.primary : AppColors.contentTertiary),
        const Gap(4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: prominent ? FontWeight.w700 : FontWeight.w500,
            color: prominent ? AppColors.primary : AppColors.contentSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyReservations extends StatelessWidget {
  const _EmptyReservations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const Gap(20),
            Text(
              'Aucun billet',
              style: AppTextStyles.headingXS,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'Vos réservations apparaîtront ici après avoir réservé un trajet.',
              style: AppTextStyles.textMMedium.copyWith(
                color: AppColors.contentTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
