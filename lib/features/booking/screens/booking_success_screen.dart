import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_button.dart';
import '../../../core/widgets/skeu_card.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class BookingSuccessScreen extends ConsumerStatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  ConsumerState<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
    HapticService.success();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    HapticService.selection();
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final reservation = ref.watch(lastReservationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Gap(24),

              // Success icon with confetti-like decoration
              AnimatedBuilder(
                animation: _scale,
                builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
                child: _SuccessHero(),
              ),

              const Gap(32),

              // Title
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      'Réservation confirmée !',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.content,
                        letterSpacing: -1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(8),
                    Text(
                      'Votre code de réservation est prêt. Présentez-vous en agence avant le départ.',
                      style: AppTextStyles.textMMedium.copyWith(
                        color: AppColors.contentSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Gap(32),

              // Reservation code card
              if (reservation != null) ...[
                FadeTransition(
                  opacity: _fade,
                  child: SkeuCard(
                    child: Column(
                      children: [
                        Text(
                          'Code de réservation',
                          style: AppTextStyles.textSMedium.copyWith(
                            color: AppColors.contentTertiary,
                          ),
                        ),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF5A0FA8), Color(0xFF761CEA)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                reservation.reservationCode,
                                style: GoogleFonts.dmSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                              const Gap(12),
                              GestureDetector(
                                onTap: () => _copyCode(reservation.reservationCode),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        if (_copied)
                          Text(
                            '✓ Copié dans le presse-papiers',
                            style: AppTextStyles.textSMedium.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Gap(16),

                // Trip summary
                FadeTransition(
                  opacity: _fade,
                  child: SkeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Votre trajet', style: AppTextStyles.headingXS),
                        const Gap(14),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                label: 'Départ',
                                value: reservation.trip.departureCity,
                                sub: Formatters.time(reservation.trip.departureTime),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            Expanded(
                              child: _SummaryItem(
                                label: 'Arrivée',
                                value: reservation.trip.arrivalCity,
                                sub: Formatters.time(reservation.trip.arrivalTime),
                                align: CrossAxisAlignment.end,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.divider, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SummaryItem(
                              label: 'Compagnie',
                              value: reservation.trip.company.name,
                            ),
                            _SummaryItem(
                              label: 'Passagers',
                              value: '${reservation.seatsCount}',
                              align: CrossAxisAlignment.end,
                            ),
                            _SummaryItem(
                              label: 'Total à payer',
                              value: Formatters.price(reservation.totalPrice),
                              align: CrossAxisAlignment.end,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Gap(24),

                // CTA
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      SkeuButton(
                        label: 'Voir mes réservations',
                        icon: Icons.confirmation_number_outlined,
                        onPressed: () {
                          HapticService.light();
                          context.go('/reservations');
                        },
                      ),
                      const Gap(12),
                      SkeuButton(
                        label: 'Nouvelle recherche',
                        variant: SkeuButtonVariant.secondary,
                        onPressed: () {
                          HapticService.light();
                          context.go('/home');
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          // Mid ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
          ),
          // Inner circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          // Confetti dots
          ..._confettiDots(),
        ],
      ),
    );
  }

  List<Widget> _confettiDots() {
    final items = [
      (Offset(20, 20), AppColors.warning, 8.0),
      (Offset(130, 25), AppColors.primary, 6.0),
      (Offset(10, 100), AppColors.success, 5.0),
      (Offset(145, 90), AppColors.error, 7.0),
      (Offset(60, 10), AppColors.primary, 5.0),
      (Offset(110, 145), AppColors.warning, 6.0),
    ];
    return items.map((d) => Positioned(
      left: d.$1.dx,
      top: d.$1.dy,
      child: Container(
        width: d.$3,
        height: d.$3,
        decoration: BoxDecoration(
          color: d.$2,
          shape: BoxShape.circle,
        ),
      ),
    )).toList();
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final CrossAxisAlignment align;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.sub,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTextStyles.textXSMedium.copyWith(
            color: AppColors.contentTertiary,
          ),
        ),
        Text(value, style: AppTextStyles.textMBold),
        if (sub != null)
          Text(
            sub!,
            style: AppTextStyles.textSMedium.copyWith(
              color: AppColors.contentTertiary,
            ),
          ),
      ],
    );
  }
}
