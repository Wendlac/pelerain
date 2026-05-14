import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_params.dart';
import '../models/trip.dart';
import '../models/company.dart';
import 'supabase_provider.dart';

final searchParamsProvider = StateProvider<SearchParams?>((ref) => null);

/// Fetches all companies once, kept in cache for the session. Used by the
/// filter sheet so the user can pick companies by name.
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final repo = ref.watch(supabaseRepositoryProvider);
  return repo.fetchCompanies();
});

/// Provides a single company by id (resolved from the cached list).
final companyByIdProvider = Provider.family<Company?, String>((ref, id) {
  final companies = ref.watch(companiesProvider).valueOrNull;
  if (companies == null) return null;
  for (final c in companies) {
    if (c.id == id) return c;
  }
  return null;
});

/// Search results state, exposed as AsyncValue so screens can render
/// loading/error/data uniformly.
final searchResultsProvider =
    StateNotifierProvider<SearchResultsNotifier, AsyncValue<List<Trip>>>(
  (ref) => SearchResultsNotifier(ref),
);

class SearchResultsNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  SearchResultsNotifier(this._ref) : super(const AsyncValue.data([]));

  final Ref _ref;

  Future<void> search(SearchParams params) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = _ref.read(supabaseRepositoryProvider);
      return repo.searchTrips(
        departureCity: params.departureCity,
        arrivalCity: params.arrivalCity,
        date: params.date,
      );
    });
  }

  void clear() => state = const AsyncValue.data([]);
}

// Sort
enum SortOption { price, time, duration }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.price);

// Filters
enum TimeSlot { any, morning, afternoon, evening }

extension TimeSlotLabel on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.any: return 'Tous';
      case TimeSlot.morning: return 'Matin (6h–12h)';
      case TimeSlot.afternoon: return 'Après-midi (12h–18h)';
      case TimeSlot.evening: return 'Soir (18h+)';
    }
  }

  String get shortLabel {
    switch (this) {
      case TimeSlot.any: return 'Tous horaires';
      case TimeSlot.morning: return 'Matin';
      case TimeSlot.afternoon: return 'Après-midi';
      case TimeSlot.evening: return 'Soir';
    }
  }
}

/// Set of selected company IDs — empty means "all"
final companyFilterProvider = StateProvider<Set<String>>((ref) => const {});

/// Selected time slot
final timeSlotFilterProvider = StateProvider<TimeSlot>((ref) => TimeSlot.any);

/// Number of active filters (for the badge)
final activeFilterCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(companyFilterProvider).isNotEmpty) count++;
  if (ref.watch(timeSlotFilterProvider) != TimeSlot.any) count++;
  return count;
});

final filteredTripsProvider = Provider<List<Trip>>((ref) {
  final results = ref.watch(searchResultsProvider);
  final sort = ref.watch(sortOptionProvider);
  final companyFilter = ref.watch(companyFilterProvider);
  final timeSlot = ref.watch(timeSlotFilterProvider);

  return results.when(
    data: (trips) {
      var filtered = List<Trip>.from(trips);

      // Company filter
      if (companyFilter.isNotEmpty) {
        filtered = filtered.where((t) => companyFilter.contains(t.company.id)).toList();
      }

      // Time slot filter
      if (timeSlot != TimeSlot.any) {
        filtered = filtered.where((t) {
          final h = t.departureTime.hour;
          switch (timeSlot) {
            case TimeSlot.morning:   return h >= 6  && h < 12;
            case TimeSlot.afternoon: return h >= 12 && h < 18;
            case TimeSlot.evening:   return h >= 18;
            case TimeSlot.any:       return true;
          }
        }).toList();
      }

      // Sort
      switch (sort) {
        case SortOption.price:
          filtered.sort((a, b) => a.price.compareTo(b.price));
        case SortOption.time:
          filtered.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        case SortOption.duration:
          filtered.sort((a, b) => a.duration.compareTo(b.duration));
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
