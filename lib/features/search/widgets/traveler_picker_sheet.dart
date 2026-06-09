import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';

/// Four traveler categories used to size the trip (per spec §3 Écran 1b).
/// Ranges are taken verbatim from the MVP doc.
enum TravelerCategory { baby, child, young, adult }

extension TravelerCategoryLabel on TravelerCategory {
  String get label {
    switch (this) {
      case TravelerCategory.baby:  return 'Bébé';
      case TravelerCategory.child: return 'Enfant';
      case TravelerCategory.young: return 'Jeune';
      case TravelerCategory.adult: return 'Adulte';
    }
  }

  String get hint {
    switch (this) {
      case TravelerCategory.baby:  return 'Moins de 3 ans';
      case TravelerCategory.child: return '3 à 12 ans';
      case TravelerCategory.young: return '12 à 25 ans';
      case TravelerCategory.adult: return '26 ans et plus';
    }
  }
}

/// Count of travelers per category. Used both for state on the home screen
/// and as the return value of the bottom sheet.
class TravelerCounts {
  final int baby;
  final int child;
  final int young;
  final int adult;

  const TravelerCounts({
    this.baby = 0,
    this.child = 0,
    this.young = 0,
    this.adult = 0,
  });

  int get total => baby + child + young + adult;

  TravelerCounts copyWith({int? baby, int? child, int? young, int? adult}) {
    return TravelerCounts(
      baby:  baby  ?? this.baby,
      child: child ?? this.child,
      young: young ?? this.young,
      adult: adult ?? this.adult,
    );
  }

  String get summary {
    if (total == 0) return 'Ajouter les voyageurs';
    return '$total voyageur${total > 1 ? 's' : ''}';
  }
}

/// Opens the traveler picker bottom sheet. Returns the new counts if the
/// user pressed "Rechercher", or `null` if they dismissed.
Future<TravelerCounts?> showTravelerPicker(
  BuildContext context, {
  required TravelerCounts initial,
}) {
  return showModalBottomSheet<TravelerCounts>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TravelerPickerSheet(initial: initial),
  );
}

class _TravelerPickerSheet extends StatefulWidget {
  final TravelerCounts initial;
  const _TravelerPickerSheet({required this.initial});

  @override
  State<_TravelerPickerSheet> createState() => _TravelerPickerSheetState();
}

class _TravelerPickerSheetState extends State<_TravelerPickerSheet> {
  late TravelerCounts _counts;

  @override
  void initState() {
    super.initState();
    _counts = widget.initial;
  }

  int _countFor(TravelerCategory c) {
    switch (c) {
      case TravelerCategory.baby:  return _counts.baby;
      case TravelerCategory.child: return _counts.child;
      case TravelerCategory.young: return _counts.young;
      case TravelerCategory.adult: return _counts.adult;
    }
  }

  void _set(TravelerCategory c, int v) {
    setState(() {
      switch (c) {
        case TravelerCategory.baby:  _counts = _counts.copyWith(baby:  v); break;
        case TravelerCategory.child: _counts = _counts.copyWith(child: v); break;
        case TravelerCategory.young: _counts = _counts.copyWith(young: v); break;
        case TravelerCategory.adult: _counts = _counts.copyWith(adult: v); break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + close
          Row(
            children: [
              Expanded(
                child: Text(
                  'Voyageurs',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.content,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.content),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const Gap(8),

          // Four categories
          ...TravelerCategory.values.map((cat) {
            final value = _countFor(cat);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _CategoryRow(
                category: cat,
                value: value,
                onMinus: value > 0 ? () => _set(cat, value - 1) : null,
                onPlus: () => _set(cat, value + 1),
              ),
            );
          }),

          const Gap(20),

          // Search button (re-uses the global pill style)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticService.medium();
                Navigator.of(context).pop(_counts);
              },
              child: const Text('Rechercher'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final TravelerCategory category;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _CategoryRow({
    required this.category,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.content,
                ),
              ),
              const Gap(2),
              Text(
                category.hint,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.contentTertiary,
                ),
              ),
            ],
          ),
        ),
        _StepperBtn(icon: Icons.remove_rounded, onTap: onMinus),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.content,
            ),
          ),
        ),
        _StepperBtn(icon: Icons.add_rounded, onTap: onPlus),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap?.call();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.tagBorder : AppColors.borderLight,
            width: 1.5,
          ),
          color: enabled ? AppColors.surface : AppColors.surface,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.content : AppColors.contentDisabled,
        ),
      ),
    );
  }
}
