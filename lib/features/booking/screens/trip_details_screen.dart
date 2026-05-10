import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_button.dart';
import '../../../core/widgets/skeu_card.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class TripDetailsScreen extends ConsumerWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 200,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  context.pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.content,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF5A0FA8),
                      const Color(0xFF761CEA),
                      const Color(0xFF9B4FFF),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.time(trip.departureTime),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                                Text(
                                  trip.departureCity,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                trip.durationLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const Gap(4),
                              Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 22,
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.time(trip.arrivalTime),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                                Text(
                                  trip.arrivalCity,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Company card — tappable → company detail
                SkeuCard(
                  onTap: () {
                    HapticService.selection();
                    context.push('/company-detail', extra: trip.company);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNeutral,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.contentSecondary,
                          size: 24,
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.company.name,
                              style: AppTextStyles.headingXS,
                            ),
                            const Gap(2),
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: i < trip.company.rating.floor()
                                      ? AppColors.warning
                                      : AppColors.border,
                                )),
                                const Gap(4),
                                Text(
                                  '${trip.company.rating}',
                                  style: AppTextStyles.textSMedium
                                      .copyWith(color: AppColors.contentTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: trip.hasAvailableSeats
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              trip.hasAvailableSeats
                                  ? '${trip.availableSeats} places'
                                  : 'Complet',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: trip.hasAvailableSeats
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Voir la compagnie →',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Gap(16),

                // Trip details
                SkeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détails du trajet', style: AppTextStyles.headingXS),
                      const Gap(16),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date de départ',
                        value: Formatters.dateLong(trip.departureTime),
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Départ',
                        value: Formatters.time(trip.departureTime),
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      _DetailRow(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Arrivée estimée',
                        value: Formatters.time(trip.arrivalTime),
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Durée estimée',
                        value: trip.durationLabel,
                      ),
                    ],
                  ),
                ),

                const Gap(16),

                // Amenities
                if (trip.amenities != null) ...[
                  SkeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Services inclus', style: AppTextStyles.headingXS),
                        const Gap(12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: trip.amenities!.split(' • ').map((a) => _AmenityChip(label: a)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                ],

                // Price breakdown
                SkeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarif', style: AppTextStyles.headingXS),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Prix par personne',
                              style: AppTextStyles.textMMedium),
                          Text(
                            Formatters.price(trip.price),
                            style: AppTextStyles.textMBold
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.warningDark,
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'Paiement en agence uniquement. Présentez votre code de réservation.',
                                style: AppTextStyles.textSMedium
                                    .copyWith(color: AppColors.content),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),

      // Sticky CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total',
                    style: AppTextStyles.textSMedium
                        .copyWith(color: AppColors.contentTertiary)),
                Text(
                  Formatters.price(trip.price),
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Gap(16),
            Expanded(
              child: SkeuButton(
                label: 'Réserver',
                icon: Icons.confirmation_number_rounded,
                onPressed: trip.hasAvailableSeats
                    ? () {
                        HapticService.medium();
                        ref.read(selectedTripProvider.notifier).state = trip;
                        context.push('/booking-form', extra: trip);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceNeutral,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.contentSecondary, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.textXSMedium
                      .copyWith(color: AppColors.contentTertiary)),
              Text(value, style: AppTextStyles.textMMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryDark,
        ),
      ),
    );
  }
}
