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
import '../../../shared/models/passenger.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const BookingFormScreen({super.key, required this.trip});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_PassengerFormData> _forms = [_PassengerFormData()];
  bool _loading = false;

  bool get _canSubmit => _forms.every((f) => f.firstName.isNotEmpty && f.lastName.isNotEmpty);

  void _addPassenger() {
    if (_forms.length >= widget.trip.availableSeats) return;
    HapticService.selection();
    setState(() => _forms.add(_PassengerFormData()));
  }

  void _removePassenger(int index) {
    if (_forms.length <= 1) return;
    HapticService.selection();
    setState(() => _forms.removeAt(index));
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    HapticService.booking();
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    final passengers = _forms.map((f) => Passenger(
      firstName: f.firstName,
      lastName: f.lastName,
      type: f.type,
    )).toList();

    ref.read(bookingPassengersProvider.notifier).state = passengers;
    ref.read(reservationsProvider.notifier).createReservation(
      trip: widget.trip,
      passengers: passengers,
    );

    if (mounted) {
      setState(() => _loading = false);
      context.go('/booking-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticService.light();
            context.pop();
          },
        ),
        title: const Text('Informations passagers'),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Trip summary
                  SkeuCard(
                    color: AppColors.primary,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.trip.departureCity} → ${widget.trip.arrivalCity}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '${Formatters.date(widget.trip.departureTime)} · ${Formatters.time(widget.trip.departureTime)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.trip.company.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              Formatters.price(widget.trip.price * _forms.length),
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Gap(24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Passagers (${_forms.length})',
                        style: AppTextStyles.headingXS,
                      ),
                      if (_forms.length < widget.trip.availableSeats)
                        TextButton.icon(
                          onPressed: _addPassenger,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Ajouter'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Gap(12),

                  ...List.generate(_forms.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PassengerForm(
                      index: i,
                      data: _forms[i],
                      canRemove: _forms.length > 1,
                      onRemove: () => _removePassenger(i),
                      onChanged: () => setState(() {}),
                    ),
                  )),

                  const Gap(8),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warningDark,
                          size: 18,
                        ),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Présentez-vous en agence au moins 30 minutes avant le départ avec votre code de réservation.',
                            style: AppTextStyles.textSMedium.copyWith(
                              color: AppColors.content,
                            ),
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
      ),

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total à payer en agence',
                    style: AppTextStyles.textSMedium
                        .copyWith(color: AppColors.contentTertiary)),
                Text(
                  Formatters.price(widget.trip.price * _forms.length),
                  style: AppTextStyles.headingXS.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Gap(12),
            SkeuButton(
              label: 'Confirmer la réservation',
              icon: Icons.check_rounded,
              onPressed: _canSubmit ? _confirm : null,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerFormData {
  String firstName = '';
  String lastName = '';
  PassengerType type = PassengerType.adult;
}

class _PassengerForm extends StatelessWidget {
  final int index;
  final _PassengerFormData data;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PassengerForm({
    required this.index,
    required this.data,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SkeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Gap(10),
              Text(
                'Passager ${index + 1}',
                style: AppTextStyles.headingXS,
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(14),

          // Type selector
          Row(
            children: [
              _TypeChip(
                label: 'Adulte',
                selected: data.type == PassengerType.adult,
                onTap: () {
                  HapticService.selection();
                  data.type = PassengerType.adult;
                  onChanged();
                },
              ),
              const Gap(8),
              _TypeChip(
                label: 'Enfant',
                selected: data.type == PassengerType.child,
                onTap: () {
                  HapticService.selection();
                  data.type = PassengerType.child;
                  onChanged();
                },
              ),
            ],
          ),

          const Gap(12),

          // First name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Prénom',
              hintText: 'Ex: Aminata',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            onChanged: (v) {
              data.firstName = v.trim();
              onChanged();
            },
          ),

          const Gap(10),

          // Last name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nom de famille',
              hintText: 'Ex: Ouédraogo',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            onChanged: (v) {
              data.lastName = v.trim();
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.contentSecondary,
          ),
        ),
      ),
    );
  }
}
