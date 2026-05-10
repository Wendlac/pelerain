import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';
import '../../shared/providers/search_provider.dart';
import '../../shared/repositories/mock_data.dart';

/// Opens the filter bottom sheet.
/// Returns true if filters were applied.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _selectedCompanies;
  late TimeSlot _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    // Copy current filter state so we can edit locally before applying
    _selectedCompanies = Set.from(ref.read(companyFilterProvider));
    _selectedTimeSlot = ref.read(timeSlotFilterProvider);
  }

  void _toggleCompany(String id) {
    HapticService.selection();
    setState(() {
      if (_selectedCompanies.contains(id)) {
        _selectedCompanies = Set.from(_selectedCompanies)..remove(id);
      } else {
        _selectedCompanies = Set.from(_selectedCompanies)..add(id);
      }
    });
  }

  void _selectTimeSlot(TimeSlot slot) {
    HapticService.selection();
    setState(() => _selectedTimeSlot = slot);
  }

  void _apply() {
    HapticService.medium();
    ref.read(companyFilterProvider.notifier).state = _selectedCompanies;
    ref.read(timeSlotFilterProvider.notifier).state = _selectedTimeSlot;
    Navigator.pop(context);
  }

  void _reset() {
    HapticService.light();
    setState(() {
      _selectedCompanies = {};
      _selectedTimeSlot = TimeSlot.any;
    });
    ref.read(companyFilterProvider.notifier).state = {};
    ref.read(timeSlotFilterProvider.notifier).state = TimeSlot.any;
    Navigator.pop(context);
  }

  int get _activeCount {
    int count = 0;
    if (_selectedCompanies.isNotEmpty) count++;
    if (_selectedTimeSlot != TimeSlot.any) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // Title row
          Row(
            children: [
              Text('Filtres', style: AppTextStyles.headingS),
              const Spacer(),
              if (_activeCount > 0)
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Réinitialiser',
                      style: AppTextStyles.textSBold.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),

          const Gap(24),

          // ── Section: Compagnies ──
          _SectionTitle(label: 'Compagnie'),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.companies.map((company) {
              final selected = _selectedCompanies.contains(company.id);
              return _FilterChip(
                label: company.name,
                selected: selected,
                onTap: () => _toggleCompany(company.id),
              );
            }).toList(),
          ),

          const Gap(24),

          // ── Section: Horaire de départ ──
          _SectionTitle(label: 'Horaire de départ'),
          const Gap(12),
          Column(
            children: [
              TimeSlot.morning,
              TimeSlot.afternoon,
              TimeSlot.evening,
            ].map((slot) {
              final selected = _selectedTimeSlot == slot;
              return _TimeSlotRow(
                slot: slot,
                selected: selected,
                onTap: () => _selectTimeSlot(
                  selected ? TimeSlot.any : slot,
                ),
              );
            }).toList(),
          ),

          const Gap(28),

          // ── Apply button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                _activeCount > 0
                    ? 'Appliquer ($_activeCount filtre${_activeCount > 1 ? 's' : ''})'
                    : 'Appliquer',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.textMMedium.copyWith(
        color: AppColors.contentTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const Gap(4),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.contentSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotRow extends StatelessWidget {
  final TimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  const _TimeSlotRow({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (slot) {
      case TimeSlot.morning:   return Icons.wb_sunny_outlined;
      case TimeSlot.afternoon: return Icons.wb_cloudy_outlined;
      case TimeSlot.evening:   return Icons.nights_stay_outlined;
      case TimeSlot.any:       return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.contentTertiary,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                slot.label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.content,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
