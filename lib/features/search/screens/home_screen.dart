import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/search_params.dart';
import '../../../shared/providers/search_provider.dart';
import '../../../shared/repositories/mock_data.dart';
import '../widgets/traveler_picker_sheet.dart';

/// Home — the only screen the voyageur sees on launch (per MVP spec §3).
///
/// Layout:
///   - Big title "Trouvez des trajets et reservez votre billet"
///   - 3 stacked cards: Où allez vous? · Quand · Voyageurs
///   - Pill CTA "Rechercher un trajet"
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Cities default to the MVP axis but can be swapped/edited
  String? _departure = 'Ouagadougou';
  String? _arrival = 'Bobo-Dioulasso';

  DateTime? _departureDate;
  DateTime? _returnDate;
  bool _isRoundTrip = false;

  TravelerCounts _travelers = const TravelerCounts(adult: 1);

  bool get _canSearch =>
      _departure != null &&
      _arrival != null &&
      _departure != _arrival &&
      _departureDate != null &&
      _travelers.total > 0;

  void _swapCities() {
    HapticService.medium();
    setState(() {
      final tmp = _departure;
      _departure = _arrival;
      _arrival = tmp;
    });
  }

  Future<void> _openCityPicker(bool isDeparture) async {
    HapticService.selection();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CityPickerSheet(
        title: isDeparture ? 'Ville de départ' : "Ville d'arrivée",
        current: isDeparture ? _departure : _arrival,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparture) {
        _departure = picked;
      } else {
        _arrival = picked;
      }
    });
  }

  Future<void> _openDatePicker() async {
    HapticService.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date de départ',
    );
    if (picked != null) setState(() => _departureDate = picked);
  }

  Future<void> _openReturnDatePicker() async {
    HapticService.selection();
    final base = _departureDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? base.add(const Duration(days: 1)),
      firstDate: base,
      lastDate: base.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date de retour',
    );
    if (picked != null) setState(() => _returnDate = picked);
  }

  Future<void> _openTravelersPicker() async {
    HapticService.selection();
    final picked = await showTravelerPicker(context, initial: _travelers);
    if (picked != null) setState(() => _travelers = picked);
  }

  Future<void> _search() async {
    if (!_canSearch) return;
    HapticService.medium();
    final params = SearchParams(
      departureCity: _departure!,
      arrivalCity: _arrival!,
      date: _departureDate!,
      passengers: _travelers.total,
      isRoundTrip: _isRoundTrip,
      returnDate: _isRoundTrip ? _returnDate : null,
    );
    ref.read(searchParamsProvider.notifier).state = params;
    if (mounted) context.push('/search-loading');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Big title (Denk One display) ──
                    Text(
                      'CHERCHEZ ET COMPAREZ\nDES TRAJETS',
                      style: AppTextStyles.pageHeadline,
                    ),
                    const Gap(28),

                    // ── Card 1: Où allez vous? ──
                    _CitiesCard(
                      departure: _departure,
                      arrival: _arrival,
                      onTapDeparture: () => _openCityPicker(true),
                      onTapArrival: () => _openCityPicker(false),
                      onSwap: _swapCities,
                    ),
                    const Gap(16),

                    // ── Card 2: Quand ──
                    _SectionCard(
                      label: 'Quand',
                      trailing: _whenLabel(),
                      isFilled: _departureDate != null,
                      onTap: _openDatePicker,
                    ),
                    if (_departureDate != null) ...[
                      const Gap(10),
                      _RoundTripToggle(
                        value: _isRoundTrip,
                        returnDate: _returnDate,
                        onChanged: (v) {
                          HapticService.selection();
                          setState(() {
                            _isRoundTrip = v;
                            if (!v) _returnDate = null;
                          });
                        },
                        onPickReturn: _openReturnDatePicker,
                      ),
                    ],
                    const Gap(16),

                    // ── Card 3: Voyageurs ──
                    _SectionCard(
                      label: 'Voyageurs',
                      trailing: _travelers.summary,
                      isFilled: _travelers.total > 0,
                      onTap: _openTravelersPicker,
                    ),
                  ],
                ),
              ),
            ),

            // ── CTA bottom ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSearch ? _search : null,
                  child: const Text('Rechercher un trajet'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _whenLabel() {
    if (_departureDate == null) return 'Ajouter des dates';
    final dep = Formatters.dateShort(_departureDate!);
    if (_isRoundTrip && _returnDate != null) {
      return '$dep → ${Formatters.dateShort(_returnDate!)}';
    }
    return dep;
  }
}

// ─── Cities card with dot rail + swap button ────────────────────────────────

class _CitiesCard extends StatelessWidget {
  final String? departure;
  final String? arrival;
  final VoidCallback onTapDeparture;
  final VoidCallback onTapArrival;
  final VoidCallback onSwap;

  const _CitiesCard({
    required this.departure,
    required this.arrival,
    required this.onTapDeparture,
    required this.onTapArrival,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Où allez vous?',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.content,
              letterSpacing: -0.3,
            ),
          ),
          const Gap(14),
          // Row layout — the rail and the swap button sit OUTSIDE the input
          // column so the input borders go from edge to edge of the
          // available space, as per the maquette.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dot rail
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 14,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.contentTertiary,
                            width: 2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 38,
                        child: CustomPaint(
                          size: const Size(2, 38),
                          painter: _DashedV(
                            color: AppColors.contentDisabled,
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),

              // City inputs — full width within their column
              Expanded(
                child: Column(
                  children: [
                    _CityField(
                      value: departure,
                      placeholder: 'Ville de départ',
                      onTap: onTapDeparture,
                    ),
                    const Gap(10),
                    _CityField(
                      value: arrival,
                      placeholder: "Ville d'arrivée",
                      onTap: onTapArrival,
                    ),
                  ],
                ),
              ),
              const Gap(12),

              // Swap button — to the right of both inputs
              GestureDetector(
                onTap: onSwap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 22,
                    color: AppColors.content,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _CityField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.contentDisabled, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value ?? placeholder,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: value == null ? FontWeight.w500 : FontWeight.w600,
            color: value == null
                ? AppColors.contentTertiary
                : AppColors.content,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DashedV extends CustomPainter {
  final Color color;
  const _DashedV({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Quand / Voyageurs card pattern (tappable row) ─────────────────────────

class _SectionCard extends StatelessWidget {
  final String label;
  final String trailing;
  final bool isFilled;
  final VoidCallback onTap;

  const _SectionCard({
    required this.label,
    required this.trailing,
    required this.isFilled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.content,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                trailing,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFilled
                      ? AppColors.content
                      : AppColors.contentTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundTripToggle extends StatelessWidget {
  final bool value;
  final DateTime? returnDate;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickReturn;

  const _RoundTripToggle({
    required this.value,
    required this.returnDate,
    required this.onChanged,
    required this.onPickReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tagBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Aller-retour',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.content,
                ),
              ),
              const Spacer(),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.content,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (value) ...[
            const Gap(8),
            GestureDetector(
              onTap: onPickReturn,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'Retour',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.contentSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    returnDate != null
                        ? Formatters.dateShort(returnDate!)
                        : 'Choisir une date',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: returnDate != null
                          ? AppColors.content
                          : AppColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── City picker bottom sheet ──────────────────────────────────────────────

class _CityPickerSheet extends StatefulWidget {
  final String title;
  final String? current;
  const _CityPickerSheet({required this.title, this.current});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  List<String> get _filtered => MockData.cities
      .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const Gap(10),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.contentDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.content,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.content),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher une ville…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.contentTertiary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final city = _filtered[i];
                  final selected = city == widget.current;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: selected
                          ? AppColors.primary
                          : AppColors.contentTertiary,
                    ),
                    title: Text(
                      city,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.content,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      HapticService.selection();
                      Navigator.of(context).pop(city);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
