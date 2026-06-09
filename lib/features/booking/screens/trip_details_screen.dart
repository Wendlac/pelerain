import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/boarding_pass_card.dart';
import '../../../core/widgets/pelerain_app_bar.dart';
import '../../../shared/models/trip.dart';

/// Trip detail — per MVP spec §3 Écran 3.
///
/// Reuses the [BoardingPassCard] so the same visual identity carries from
/// the results list to the detail. Below the card, the agency-payment
/// warning is highlighted in a warm orange box. Two stacked CTAs:
/// - primary: "Voir les informations de la compagnie" → /company-detail
/// - secondary outline: "Rechercher un autre trajet"   → /home
class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PelerainAppBar(
            appBarTitle: 'Voyages',
            sectionTitle: 'Détails offre',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BoardingPassCard(trip: trip),
                  const Gap(20),
                  const _PaymentWarning(),
                ],
              ),
            ),
          ),

          // ── CTAs ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticService.medium();
                      context.push('/company-detail', extra: trip.company);
                    },
                    icon: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 20,
                      color: AppColors.content,
                    ),
                    label: const Text(
                      'Voir les informations de la compagnie',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticService.light();
                      context.go('/home');
                    },
                    child: const Text('Rechercher un autre trajet'),
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

class _PaymentWarning extends StatelessWidget {
  const _PaymentWarning();

  @override
  Widget build(BuildContext context) {
    // The disclaimer from MVP spec §5. Warm orange tone — matches the
    // friendliness of the brand without being aggressive like a red error.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD8), // soft peach
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              "Les paiements se font sur place à l'agence. "
              'Veuillez contacter la compagnie pour plus de détails',
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                color: AppColors.warningDark,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
