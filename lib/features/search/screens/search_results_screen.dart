import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/boarding_pass_card.dart';
import '../../../core/widgets/pelerain_app_bar.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/search_provider.dart';

/// Search results — per MVP spec §3 Écran 2.
///
/// Header: small "Trajets" + section title "Voyages disponibles".
/// Filter row: "Filtrer par" + 3 dropdown chips (Prix · Compagnie · Heure).
/// Body: list of [BoardingPassCard]s.
/// Footer: pill CTA "Rechercher un autre trajet" to go back home.
class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final trips = ref.watch(filteredTripsProvider);
    final activeFilterCount = ref.watch(activeFilterCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PelerainAppBar(
            appBarTitle: 'Trajets',
            sectionTitle: 'Voyages disponibles',
          ),

          // Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrer par',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.content,
                  ),
                ),
                const Gap(10),
                Row(
                  children: [
                    _FilterChip(
                      label: _priceFilterLabel(ref.watch(sortOptionProvider)),
                      onTap: () => _openPriceMenu(context, ref),
                    ),
                    const Gap(8),
                    _FilterChip(
                      label: 'Compagnie',
                      onTap: () => _openCompanyFilter(context, ref),
                    ),
                    const Gap(8),
                    _FilterChip(
                      label: _timeSlotLabel(ref.watch(timeSlotFilterProvider)),
                      onTap: () => _openTimeMenu(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Une erreur est survenue lors de la recherche.\n$e',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: AppColors.contentSecondary,
                    ),
                  ),
                ),
              ),
              data: (_) => _ResultsList(
                trips: trips,
                hasActiveFilters: activeFilterCount > 0,
                onClearFilters: () {
                  ref.read(companyFilterProvider.notifier).state = {};
                  ref.read(timeSlotFilterProvider.notifier).state = TimeSlot.any;
                  ref.read(sortOptionProvider.notifier).state = SortOption.price;
                },
              ),
            ),
          ),

          // ── Bottom CTA — return to home ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.light();
                  context.go('/home');
                },
                child: const Text('Rechercher un autre trajet'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _priceFilterLabel(SortOption opt) {
    switch (opt) {
      case SortOption.price:    return 'Prix';
      case SortOption.time:     return 'Heure';
      case SortOption.duration: return 'Durée';
    }
  }

  String _timeSlotLabel(TimeSlot s) {
    if (s == TimeSlot.any) return 'Heure';
    return s.shortLabel;
  }

  Future<void> _openPriceMenu(BuildContext context, WidgetRef ref) async {
    HapticService.light();
    final picked = await showModalBottomSheet<SortOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleMenuSheet<SortOption>(
        title: 'Trier par',
        options: const [
          ('Prix croissant',     SortOption.price),
          ('Heure de départ',    SortOption.time),
          ('Durée du trajet',    SortOption.duration),
        ],
      ),
    );
    if (picked != null) {
      ref.read(sortOptionProvider.notifier).state = picked;
    }
  }

  Future<void> _openTimeMenu(BuildContext context, WidgetRef ref) async {
    HapticService.light();
    final picked = await showModalBottomSheet<TimeSlot>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleMenuSheet<TimeSlot>(
        title: 'Heure de départ',
        options: const [
          ('Tous horaires', TimeSlot.any),
          ('Matin (6h–12h)', TimeSlot.morning),
          ('Après-midi (12h–18h)', TimeSlot.afternoon),
          ('Soir (18h+)', TimeSlot.evening),
        ],
      ),
    );
    if (picked != null) {
      ref.read(timeSlotFilterProvider.notifier).state = picked;
    }
  }

  Future<void> _openCompanyFilter(BuildContext context, WidgetRef ref) async {
    HapticService.light();
    final companies = ref.read(companiesProvider).valueOrNull ?? [];
    if (companies.isEmpty) return;

    final current = ref.read(companyFilterProvider);
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompanyFilterSheet(
        companies:
            companies.map((c) => (c.id, c.name)).toList(growable: false),
        initialSelected: current,
      ),
    );
    if (picked != null) {
      ref.read(companyFilterProvider.notifier).state = picked;
    }
  }
}

// ─── Filter chip ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.tagBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.content,
              ),
            ),
            const Gap(4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.content,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Results list ──────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<Trip> trips;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _ResultsList({
    required this.trips,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppColors.contentTertiary,
              ),
              const Gap(16),
              Text(
                hasActiveFilters
                    ? 'Aucun trajet ne correspond à vos filtres.'
                    : 'Aucun trajet disponible pour ces critères.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppColors.contentSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasActiveFilters) ...[
                const Gap(16),
                OutlinedButton(
                  onPressed: onClearFilters,
                  child: const Text('Effacer les filtres'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const Gap(14),
      itemBuilder: (ctx, i) => BoardingPassCard(
        trip: trips[i],
        compact: true,
        onTap: () {
          HapticService.selection();
          ctx.push('/trip-details', extra: trips[i]);
        },
      ),
    );
  }
}

// ─── Bottom-sheet helpers ──────────────────────────────────────────────────

/// Simple "pick one" sheet used by the Prix and Heure chips.
class _SimpleMenuSheet<T> extends StatelessWidget {
  final String title;
  final List<(String, T)> options;
  const _SimpleMenuSheet({required this.title, required this.options});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.content,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.content),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Gap(4),
          ...options.map(
            (o) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                o.$1,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.content,
                ),
              ),
              onTap: () => Navigator.of(context).pop(o.$2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyFilterSheet extends StatefulWidget {
  final List<(String id, String name)> companies;
  final Set<String> initialSelected;
  const _CompanyFilterSheet({
    required this.companies,
    required this.initialSelected,
  });

  @override
  State<_CompanyFilterSheet> createState() => _CompanyFilterSheetState();
}

class _CompanyFilterSheetState extends State<_CompanyFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  void _toggle(String id) {
    HapticService.selection();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtrer par compagnie',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.content,
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
          ...widget.companies.map((c) {
            final picked = _selected.contains(c.$1);
            return CheckboxListTile(
              value: picked,
              onChanged: (_) => _toggle(c.$1),
              activeColor: AppColors.primary,
              checkColor: AppColors.content,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                c.$2,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.content,
                ),
              ),
            );
          }),
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}
