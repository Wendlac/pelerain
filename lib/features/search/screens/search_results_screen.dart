import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/skeu_card.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/search_provider.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../core/utils/formatters.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(searchParamsProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final trips = ref.watch(filteredTripsProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final activeFilterCount = ref.watch(activeFilterCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                HapticService.light();
                context.pop();
              },
            ),
            title: params != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            params.departureCity,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.content,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 14, color: AppColors.primary),
                          ),
                          Text(
                            params.arrivalCity,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.content,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${Formatters.date(params.date)} · ${params.passengers} passager${params.passengers > 1 ? 's' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.contentTertiary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                : const Text('Résultats'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _FilterButton(
                  activeCount: activeFilterCount,
                  onTap: () {
                    HapticService.light();
                    showFilterSheet(context);
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _SortBar(selected: sortOption),
            ),
          ),

          // Content
          resultsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    Gap(16),
                    Text('Recherche en cours...'),
                  ],
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $e')),
            ),
            data: (_) {
              if (trips.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverList.separated(
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (ctx, i) => TripCard(
                    trip: trips[i],
                    onTap: () {
                      HapticService.selection();
                      ref.read(selectedTripProvider.notifier).state = trips[i];
                      ctx.push('/trip-details', extra: trips[i]);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SortBar extends ConsumerWidget {
  final SortOption selected;
  const _SortBar({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            'Trier par :',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.contentTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(8),
          ...[
            (SortOption.price, 'Prix'),
            (SortOption.time, 'Heure'),
            (SortOption.duration, 'Durée'),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _SortChip(
              label: e.$2,
              selected: selected == e.$1,
              onTap: () {
                HapticService.selection();
                ref.read(sortOptionProvider.notifier).state = e.$1;
              },
            ),
          )),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFull = trip.status == TripStatus.full;

    return Opacity(
      opacity: isFull ? 0.6 : 1,
      child: SkeuCard(
        onTap: isFull ? null : onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: company + price
            Row(
              children: [
                // Company badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    trip.company.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.price(trip.price),
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'par personne',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.contentTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Gap(14),

            // Time row
            Row(
              children: [
                // Departure
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.time(trip.departureTime),
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.content,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      trip.departureCity,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.contentSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Duration line
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          trip.durationLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.contentTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            const Icon(
                              Icons.directions_bus_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Arrival
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.time(trip.arrivalTime),
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.content,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      trip.arrivalCity,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.contentSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Gap(12),
            const Divider(color: AppColors.divider, height: 1),
            const Gap(10),

            // Footer: seats + amenities badge
            Row(
              children: [
                if (isFull)
                  _Badge(label: 'Complet', color: AppColors.error)
                else if (trip.isAlmostFull)
                  _Badge(
                    label: '${trip.availableSeats} places restantes',
                    color: AppColors.warning,
                    textColor: AppColors.content,
                  )
                else
                  _Badge(
                    label: '${trip.availableSeats} places',
                    color: AppColors.success.withValues(alpha: 0.1),
                    textColor: AppColors.success,
                  ),
                const Gap(8),
                if (trip.amenities != null)
                  Expanded(
                    child: Text(
                      trip.amenities!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.contentTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (!isFull)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _Badge({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color.a < 0.3 ? 1 : 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor ?? color,
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters = ref.watch(activeFilterCountProvider) > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.filter_list_off_rounded : Icons.directions_bus_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const Gap(20),
            Text(
              hasFilters ? 'Aucun résultat pour ces filtres' : 'Aucun trajet trouvé',
              style: AppTextStyles.headingXS,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              hasFilters
                  ? 'Modifiez ou supprimez vos filtres pour voir plus de trajets.'
                  : 'Essayez une autre date ou un autre itinéraire.',
              style: AppTextStyles.textMMedium.copyWith(color: AppColors.contentTertiary),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const Gap(20),
              GestureDetector(
                onTap: () {
                  ref.read(companyFilterProvider.notifier).state = {};
                  ref.read(timeSlotFilterProvider.notifier).state = TimeSlot.any;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'Effacer les filtres',
                    style: AppTextStyles.textSBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeCount > 0 ? AppColors.primarySurface : AppColors.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: activeCount > 0 ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: activeCount > 0 ? AppColors.primary : AppColors.contentSecondary,
                ),
                const Gap(4),
                Text(
                  'Filtrer',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeCount > 0 ? AppColors.primary : AppColors.contentSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (activeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
