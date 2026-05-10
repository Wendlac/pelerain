import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_button.dart';
import '../../../shared/models/search_params.dart';
import '../../../shared/providers/search_provider.dart';
import '../../../shared/repositories/mock_data.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _departure;
  String? _arrival;

  // Departure date/time
  DateTime _date = DateTime.now();
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);

  // Round trip
  bool _isRoundTrip = false;
  DateTime _returnDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _returnTime = const TimeOfDay(hour: 17, minute: 0);

  // Passengers
  int _passengers = 1;

  bool get _canSearch =>
      _departure != null && _arrival != null && _departure != _arrival;

  void _swapCities() {
    HapticService.medium();
    setState(() {
      final tmp = _departure;
      _departure = _arrival;
      _arrival = tmp;
    });
  }

  Future<void> _pickDate({required bool isReturn}) async {
    HapticService.selection();
    final initial = isReturn ? _returnDate : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnDate = picked;
        } else {
          _date = picked;
          // If return date is before new departure date, bump it
          if (_isRoundTrip && _returnDate.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _pickTime({required bool isReturn}) async {
    HapticService.selection();
    final initial = isReturn ? _returnTime : _departureTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnTime = picked;
        } else {
          _departureTime = picked;
        }
      });
    }
  }

  Future<void> _search() async {
    if (!_canSearch) return;
    HapticService.medium();
    final params = SearchParams(
      departureCity: _departure!,
      arrivalCity: _arrival!,
      date: _date,
      departureTime: _departureTime,
      passengers: _passengers,
      isRoundTrip: _isRoundTrip,
      returnDate: _isRoundTrip ? _returnDate : null,
      returnTime: _isRoundTrip ? _returnTime : null,
    );
    ref.read(searchParamsProvider.notifier).state = params;
    await ref.read(searchResultsProvider.notifier).search(params);
    if (mounted) context.push('/search-results');
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.add(const Duration(days: 1))) return 'Demain';
    return Formatters.date(date);
  }

  String _formatTimeLabel(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110), // 110 = space for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Text(
                'Bonjour 👋',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.contentTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(4),
              Text(
                'Où voyagez-\nvous ?',
                style: GoogleFonts.dmSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.content,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),

              const Gap(20),

              // ── Search Card ──
              _SearchCard(
                departure: _departure,
                arrival: _arrival,
                date: _date,
                departureTime: _departureTime,
                returnDate: _returnDate,
                returnTime: _returnTime,
                isRoundTrip: _isRoundTrip,
                passengers: _passengers,
                onSwap: _swapCities,
                onDepartureChanged: (v) => setState(() => _departure = v),
                onArrivalChanged: (v) => setState(() => _arrival = v),
                onToggleRoundTrip: (v) {
                  HapticService.selection();
                  setState(() => _isRoundTrip = v);
                },
                onPickDepartureDate: () => _pickDate(isReturn: false),
                onPickDepartureTime: () => _pickTime(isReturn: false),
                onPickReturnDate: () => _pickDate(isReturn: true),
                onPickReturnTime: () => _pickTime(isReturn: true),
                onPassengersChanged: (v) => setState(() => _passengers = v),
                formatDate: _formatDateLabel,
                formatTime: _formatTimeLabel,
              ),

              const Gap(16),

              // ── Search CTA ──
              SkeuButton(
                label: 'Rechercher',
                icon: Icons.search_rounded,
                onPressed: _canSearch ? _search : null,
              ),

              const Gap(32),

              // ── Popular routes ──
              Text(
                'Trajets populaires',
                style: AppTextStyles.headingXS.copyWith(color: AppColors.content),
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('Ouagadougou', 'Bobo-Dioulasso'),
                  ('Ouagadougou', 'Koudougou'),
                  ('Bobo-Dioulasso', 'Banfora'),
                  ('Ouagadougou', 'Kaya'),
                ].map((r) => _RouteChip(
                  from: r.$1,
                  to: r.$2,
                  onTap: () {
                    HapticService.selection();
                    setState(() {
                      _departure = r.$1;
                      _arrival = r.$2;
                    });
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Card ─────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final String? departure;
  final String? arrival;
  final DateTime date;
  final TimeOfDay departureTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final bool isRoundTrip;
  final int passengers;
  final VoidCallback onSwap;
  final ValueChanged<String?> onDepartureChanged;
  final ValueChanged<String?> onArrivalChanged;
  final ValueChanged<bool> onToggleRoundTrip;
  final VoidCallback onPickDepartureDate;
  final VoidCallback onPickDepartureTime;
  final VoidCallback onPickReturnDate;
  final VoidCallback onPickReturnTime;
  final ValueChanged<int> onPassengersChanged;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;

  const _SearchCard({
    required this.departure,
    required this.arrival,
    required this.date,
    required this.departureTime,
    required this.returnDate,
    required this.returnTime,
    required this.isRoundTrip,
    required this.passengers,
    required this.onSwap,
    required this.onDepartureChanged,
    required this.onArrivalChanged,
    required this.onToggleRoundTrip,
    required this.onPickDepartureDate,
    required this.onPickDepartureTime,
    required this.onPickReturnDate,
    required this.onPickReturnTime,
    required this.onPassengersChanged,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── City selector ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Où allez vous?',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                    letterSpacing: -0.3,
                  ),
                ),
                const Gap(16),

                // Departure + Arrival with visual indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Visual indicator column
                    SizedBox(
                      width: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Departure dot (outline circle)
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
                          // Dashed vertical line
                          _DashedVertical(height: 38),
                          // Arrival dot (filled blue)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF761CEA),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    // City fields
                    Expanded(
                      child: Column(
                        children: [
                          // Departure
                          _CityRow(
                            value: departure,
                            placeholder: 'Ville de départ',
                            onTap: () => _openCityPicker(
                              context,
                              title: 'Départ',
                              selected: departure,
                              onSelected: onDepartureChanged,
                            ),
                          ),
                          const Gap(6),
                          const Divider(color: Color(0xFFEEEEEE), height: 1),
                          const Gap(6),
                          // Arrival
                          _CityRow(
                            value: arrival,
                            placeholder: "Ville d'arrivée",
                            onTap: () => _openCityPicker(
                              context,
                              title: 'Arrivée',
                              selected: arrival,
                              onSelected: onArrivalChanged,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    // Swap button
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF0F0F0), height: 1),

          // ── Quand ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Quand',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.content,
                      ),
                    ),
                    const Spacer(),
                    // Aller-retour toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isRoundTrip,
                            onChanged: onToggleRoundTrip,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.success,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Aller retour',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isRoundTrip
                                ? AppColors.content
                                : AppColors.contentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Date fields (show when toggle off → just 1 row, toggle on → 2 rows)
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    children: [
                      const Gap(10),
                      // Departure date+time row
                      _DateTimeRow(
                        icon: Icons.north_east_rounded,
                        iconColor: AppColors.primary,
                        dateLabel: formatDate(date),
                        timeLabel: formatTime(departureTime),
                        onDateTap: onPickDepartureDate,
                        onTimeTap: onPickDepartureTime,
                      ),
                      if (isRoundTrip) ...[
                        const Gap(8),
                        _DateTimeRow(
                          icon: Icons.south_west_rounded,
                          iconColor: AppColors.contentSecondary,
                          dateLabel: formatDate(returnDate),
                          timeLabel: formatTime(returnTime),
                          onDateTap: onPickReturnDate,
                          onTimeTap: onPickReturnTime,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF0F0F0), height: 1),

          // ── Voyageurs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Row(
              children: [
                Text(
                  'Voyageurs',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                  ),
                ),
                const Spacer(),
                // Stepper inline
                Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      onTap: passengers > 1
                          ? () => onPassengersChanged(passengers - 1)
                          : null,
                    ),
                    const Gap(12),
                    Text(
                      '$passengers',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.content,
                      ),
                    ),
                    Text(
                      ' voyageur${passengers > 1 ? 's' : ''}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.contentSecondary,
                      ),
                    ),
                    const Gap(12),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      onTap: passengers < 10
                          ? () => onPassengersChanged(passengers + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCityPicker(
    BuildContext context, {
    required String title,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    HapticService.selection();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CityPickerSheet(title: title, selected: selected),
    );
    if (result != null) onSelected(result);
  }
}

// ─── City row (tap to pick) ───────────────────────────────────────────────────

class _CityRow extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _CityRow({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value ?? placeholder,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
              color: value != null ? AppColors.content : AppColors.contentDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date + Time row ─────────────────────────────────────────────────────────

class _DateTimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeRow({
    required this.icon,
    required this.iconColor,
    required this.dateLabel,
    required this.timeLabel,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const Gap(10),
        // Date field
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dateLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.content,
                ),
              ),
            ),
          ),
        ),
        const Gap(8),
        // Time field
        GestureDetector(
          onTap: onTimeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              timeLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.content,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dashed vertical line ─────────────────────────────────────────────────────

class _DashedVertical extends StatelessWidget {
  final double height;
  const _DashedVertical({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.5;

    double y = 0;
    const dashH = 4.0;
    const gapH = 3.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashH), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Step button ──────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticService.selection();
          onTap!();
        }
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? AppColors.primarySurface : const Color(0xFFF2F2F2),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.borderLight : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.primary : AppColors.contentDisabled,
        ),
      ),
    );
  }
}

// ─── Route chip ───────────────────────────────────────────────────────────────

class _RouteChip extends StatelessWidget {
  final String from;
  final String to;
  final VoidCallback onTap;
  const _RouteChip({required this.from, required this.to, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              from,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.contentSecondary,
              ),
            ),
            const Gap(6),
            const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
            const Gap(6),
            Text(
              to,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── City picker sheet ────────────────────────────────────────────────────────

class _CityPickerSheet extends StatefulWidget {
  final String title;
  final String? selected;
  const _CityPickerSheet({required this.title, this.selected});

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
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choisir : ${widget.title}', style: AppTextStyles.headingXS),
                  const Gap(12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ville...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, i) {
                  final city = _filtered[i];
                  final isSelected = city == widget.selected;
                  return ListTile(
                    title: Text(
                      city,
                      style: GoogleFonts.dmSans(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.content,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      HapticService.selection();
                      Navigator.pop(context, city);
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
